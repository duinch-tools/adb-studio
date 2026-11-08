use std::path::Path;
use std::process::Command;

#[derive(Clone)]
pub struct CapturedImage {
    pub width: usize,
    pub height: usize,
    pub rgba: Vec<u8>,
}

impl std::fmt::Debug for CapturedImage {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("CapturedImage")
            .field("width", &self.width)
            .field("height", &self.height)
            .field("rgba_len", &self.rgba.len())
            .finish()
    }
}

pub struct CaptureAdapter;

impl CaptureAdapter {
    pub fn capture_screen(adb_path: &Path, device_id: &str) -> Result<CapturedImage, String> {
        let output = Command::new(adb_path)
            .args(["-s", device_id, "exec-out", "screencap", "-p"])
            .output()
            .map_err(|e| format!("Failed to run screencap: {e}"))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            return Err(format!("screencap failed: {err}"));
        }

        let bytes = output.stdout;
        if bytes.is_empty() {
            return Err("Empty screenshot buffer received from device".into());
        }

        let img = image::load_from_memory(&bytes)
            .map_err(|e| format!("Failed to decode PNG screenshot: {e}"))?
            .to_rgba8();

        let (w, h) = img.dimensions();
        Ok(CapturedImage {
            width: w as usize,
            height: h as usize,
            rgba: img.into_raw(),
        })
    }
}
