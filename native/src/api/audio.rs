use crate::dsp::{denoiser::StreamingDenoiser, level, noise, wav};
use flutter_rust_bridge::frb;

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub enum NoiseKind {
    White,
    Pink,
    Brown,
}

pub fn calculate_db(buffer: Vec<f32>) -> f32 {
    level::rms_db(&buffer)
}

pub fn calculate_peak_db(buffer: Vec<f32>) -> f32 {
    level::peak_db(&buffer)
}

pub fn process_audio_chunk(buffer: Vec<f32>, noise_threshold: f32) -> Vec<f32> {
    let mut denoiser = StreamingDenoiser::new(44_100, noise_threshold);
    let mut output = denoiser.process(&buffer);
    output.extend(denoiser.flush());
    output
}

#[frb(opaque)]
pub struct AudioDenoiser {
    inner: StreamingDenoiser,
}

pub fn create_denoiser(sample_rate: u32, noise_threshold: f32) -> AudioDenoiser {
    AudioDenoiser {
        inner: StreamingDenoiser::new(sample_rate, noise_threshold),
    }
}

impl AudioDenoiser {
    pub fn process(&mut self, buffer: Vec<f32>) -> Vec<f32> {
        self.inner.process(&buffer)
    }

    pub fn flush(&mut self) -> Vec<f32> {
        self.inner.flush()
    }
}

pub fn generate_noise_wav(kind: NoiseKind, seconds: u32, sample_rate: u32) -> Vec<u8> {
    let color = match kind {
        NoiseKind::White => noise::Color::White,
        NoiseKind::Pink => noise::Color::Pink,
        NoiseKind::Brown => noise::Color::Brown,
    };
    let samples = noise::generate(color, seconds, sample_rate);
    wav::encode_pcm16_mono(&samples, sample_rate)
}

pub fn encode_wav(samples: Vec<f32>, sample_rate: u32) -> Vec<u8> {
    wav::encode_pcm16_mono(&samples, sample_rate)
}
