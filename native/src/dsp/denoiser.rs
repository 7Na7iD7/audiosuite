use rustfft::{num_complex::Complex, Fft, FftPlanner};
use std::f32::consts::PI;
use std::sync::Arc;

const FRAME: usize = 1024;
const HOP: usize = FRAME / 2;
const BINS: usize = FRAME / 2 + 1;
const WARMUP_FRAMES: u32 = 40;

pub struct StreamingDenoiser {
    forward: Arc<dyn Fft<f32>>,
    inverse: Arc<dyn Fft<f32>>,
    window: Vec<f32>,
    noise_floor: Vec<f32>,
    gain_state: Vec<f32>,
    pending: Vec<f32>,
    overlap: Vec<f32>,
    spectrum: Vec<Complex<f32>>,
    scratch: Vec<Complex<f32>>,
    over_subtraction: f32,
    spectral_floor: f32,
    gate_level: f32,
    rise: f32,
    frames_seen: u32,
    consumed: usize,
    emitted: usize,
}

impl StreamingDenoiser {
    pub fn new(sample_rate: u32, threshold: f32) -> Self {
        let t = threshold.clamp(0.0, 1.0);
        let mut planner = FftPlanner::<f32>::new();
        let forward = planner.plan_fft_forward(FRAME);
        let inverse = planner.plan_fft_inverse(FRAME);
        let scratch_len = forward
            .get_inplace_scratch_len()
            .max(inverse.get_inplace_scratch_len());
        let window = (0..FRAME)
            .map(|i| (PI * (i as f32 + 0.5) / FRAME as f32).sin())
            .collect();
        let rate = sample_rate.max(8_000) as f32;
        Self {
            forward,
            inverse,
            window,
            noise_floor: vec![0.0; BINS],
            gain_state: vec![1.0; BINS],
            pending: Vec::with_capacity(FRAME * 4),
            overlap: vec![0.0; FRAME],
            spectrum: vec![Complex::new(0.0, 0.0); FRAME],
            scratch: vec![Complex::new(0.0, 0.0); scratch_len],
            over_subtraction: 1.0 + 3.0 * t,
            spectral_floor: 0.06 - 0.04 * t,
            gate_level: 0.0003 + 0.02 * t * t,
            rise: 1.6_f32.powf(HOP as f32 / rate),
            frames_seen: 0,
            consumed: 0,
            emitted: 0,
        }
    }

    pub fn process(&mut self, samples: &[f32]) -> Vec<f32> {
        self.consumed += samples.len();
        self.pending.extend_from_slice(samples);
        let mut out = Vec::with_capacity(samples.len() + HOP);
        while self.pending.len() >= FRAME {
            self.process_frame();
            out.extend_from_slice(&self.overlap[..HOP]);
            self.overlap.copy_within(HOP.., 0);
            for v in &mut self.overlap[HOP..] {
                *v = 0.0;
            }
            self.pending.drain(..HOP);
        }
        self.emitted += out.len();
        out
    }

    pub fn flush(&mut self) -> Vec<f32> {
        let missing = self.consumed.saturating_sub(self.emitted);
        if missing == 0 {
            return Vec::new();
        }
        let consumed = self.consumed;
        let emitted = self.emitted;
        let zeros = vec![0.0_f32; FRAME * 3];
        let mut tail = self.process(&zeros);
        tail.truncate(missing);
        self.consumed = consumed;
        self.emitted = emitted + tail.len();
        tail
    }

    fn process_frame(&mut self) {
        let mut energy = 0.0_f32;
        for i in 0..FRAME {
            let s = self.pending[i];
            energy += s * s;
            self.spectrum[i] = Complex::new(s * self.window[i], 0.0);
        }
        let frame_rms = (energy / FRAME as f32).sqrt();
        let gate = if frame_rms < self.gate_level { 0.15 } else { 1.0 };

        self.forward
            .process_with_scratch(&mut self.spectrum, &mut self.scratch);

        for k in 0..BINS {
            let mag = self.spectrum[k].norm();
            let mut floor = self.noise_floor[k];
            if self.frames_seen == 0 {
                floor = mag;
            } else if self.frames_seen < WARMUP_FRAMES {
                floor = floor * 0.9 + mag * 0.1;
            } else if mag < floor {
                floor = floor * 0.8 + mag * 0.2;
            } else {
                floor = (floor * self.rise).min(mag);
            }
            self.noise_floor[k] = floor;

            let raw_gain = if mag > 1e-9 {
                (1.0 - self.over_subtraction * floor / mag).max(self.spectral_floor)
            } else {
                self.spectral_floor
            };
            let target = raw_gain * gate;
            let previous = self.gain_state[k];
            let gain = if target > previous {
                previous * 0.5 + target * 0.5
            } else {
                previous * 0.8 + target * 0.2
            };
            self.gain_state[k] = gain;

            self.spectrum[k] *= gain;
            if k > 0 && k < FRAME / 2 {
                self.spectrum[FRAME - k] *= gain;
            }
        }

        self.inverse
            .process_with_scratch(&mut self.spectrum, &mut self.scratch);

        let norm = 1.0 / FRAME as f32;
        for i in 0..FRAME {
            self.overlap[i] += self.spectrum[i].re * norm * self.window[i];
        }
        self.frames_seen = self.frames_seen.saturating_add(1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn output_length_matches_input_after_flush() {
        let mut d = StreamingDenoiser::new(44_100, 0.5);
        let input: Vec<f32> = (0..10_000).map(|i| ((i as f32) * 0.05).sin() * 0.3).collect();
        let mut out = Vec::new();
        for chunk in input.chunks(1_777) {
            out.extend(d.process(chunk));
        }
        out.extend(d.flush());
        assert_eq!(out.len(), input.len());
    }
}
