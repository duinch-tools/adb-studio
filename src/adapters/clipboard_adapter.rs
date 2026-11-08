use arboard::{Clipboard, ImageData};
use std::borrow::Cow;

pub struct ClipboardAdapter;

impl ClipboardAdapter {
    pub fn copy_text(text: &str) -> Result<(), String> {
        let mut clipboard = Clipboard::new().map_err(|e| format!("Clipboard error: {e}"))?;
        clipboard
            .set_text(text)
            .map_err(|e| format!("Failed to copy text: {e}"))
    }

    pub fn copy_rgba_image(width: usize, height: usize, rgba: &[u8]) -> Result<(), String> {
        let mut clipboard = Clipboard::new().map_err(|e| format!("Clipboard error: {e}"))?;
        let data = ImageData {
            width,
            height,
            bytes: Cow::Borrowed(rgba),
        };
        clipboard
            .set_image(data)
            .map_err(|e| format!("Failed to copy image to clipboard: {e}"))
    }
}
