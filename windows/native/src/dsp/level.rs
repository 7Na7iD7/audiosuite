pub const SILENCE_DB: f32 = -120.0;

pub fn rms(buffer: &[f32]) -> f32 {
    if buffer.is_empty() {
        return 0.0;
    }
    let sum: f64 = buffer.iter().map(|s| f64::from(*s) * f64::from(*s)).sum();
    (sum / buffer.len() as f64).sqrt() as f32
}

pub fn to_db(amplitude: f32) -> f32 {
    if amplitude <= 1e-6 {
        SILENCE_DB
    } else {
        (20.0 * amplitude.log10()).max(SILENCE_DB)
    }
}

pub fn rms_db(buffer: &[f32]) -> f32 {
    to_db(rms(buffer))
}

pub fn peak_db(buffer: &[f32]) -> f32 {
    let peak = buffer.iter().fold(0.0_f32, |acc, s| acc.max(s.abs()));
    to_db(peak)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn full_scale_square_is_zero_db() {
        let buffer = vec![1.0_f32, -1.0, 1.0, -1.0];
        assert!(rms_db(&buffer).abs() < 1e-4);
    }

    #[test]
    fn silence_is_floor() {
        assert_eq!(rms_db(&[0.0; 128]), SILENCE_DB);
    }
}
