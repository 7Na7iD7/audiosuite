use std::f32::consts::FRAC_PI_2;

#[derive(Clone, Copy)]
pub enum Color {
    White,
    Pink,
    Brown,
}

struct XorShift(u64);

impl XorShift {
    fn new(seed: u64) -> Self {
        Self(seed.max(1))
    }

    fn next_sample(&mut self) -> f32 {
        let mut x = self.0;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.0 = x;
        ((x >> 40) as f32 / 8_388_608.0) - 1.0
    }
}

fn white(rng: &mut XorShift, len: usize) -> Vec<f32> {
    (0..len).map(|_| rng.next_sample()).collect()
}

fn pink(rng: &mut XorShift, len: usize) -> Vec<f32> {
    let (mut b0, mut b1, mut b2, mut b3, mut b4, mut b5, mut b6) =
        (0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32);
    let mut out = Vec::with_capacity(len);
    for _ in 0..len {
        let w = rng.next_sample();
        b0 = 0.99886 * b0 + w * 0.0555179;
        b1 = 0.99332 * b1 + w * 0.0750759;
        b2 = 0.96900 * b2 + w * 0.1538520;
        b3 = 0.86650 * b3 + w * 0.3104856;
        b4 = 0.55000 * b4 + w * 0.5329522;
        b5 = -0.7616 * b5 - w * 0.0168980;
        out.push(b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362);
        b6 = w * 0.115926;
    }
    out
}

fn brown(rng: &mut XorShift, len: usize) -> Vec<f32> {
    let mut last = 0.0_f32;
    let mut out = Vec::with_capacity(len);
    for _ in 0..len {
        let w = rng.next_sample();
        last = (last + 0.02 * w) / 1.02;
        out.push(last * 3.5);
    }
    out
}

fn normalize(samples: &mut [f32], target_peak: f32) {
    let mean = samples.iter().sum::<f32>() / samples.len().max(1) as f32;
    let mut peak = 0.0_f32;
    for s in samples.iter_mut() {
        *s -= mean;
        peak = peak.max(s.abs());
    }
    if peak > 0.0 {
        let gain = target_peak / peak;
        for s in samples.iter_mut() {
            *s *= gain;
        }
    }
}

pub fn generate(color: Color, seconds: u32, sample_rate: u32) -> Vec<f32> {
    let len = (seconds as usize * sample_rate as usize).max(1);
    let fade = (sample_rate as usize / 2).min(len / 2).max(1);
    let total = len + fade;
    let mut rng = XorShift::new(0x9E37_79B9_7F4A_7C15);
    let raw = match color {
        Color::White => white(&mut rng, total),
        Color::Pink => pink(&mut rng, total),
        Color::Brown => brown(&mut rng, total),
    };
    let mut out: Vec<f32> = raw[..len].to_vec();
    for i in 0..fade {
        let t = i as f32 / fade as f32;
        let head = (t * FRAC_PI_2).sin();
        let tail = (t * FRAC_PI_2).cos();
        out[i] = raw[i] * head + raw[len + i] * tail;
    }
    normalize(&mut out, 0.85);
    out
}
