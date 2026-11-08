use super::capture_adapter::{CaptureAdapter, CapturedImage};
use crossbeam_channel::Sender;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;
use std::time::Duration;

#[derive(Default)]
pub struct LivePreviewWorker {
    is_running: Arc<AtomicBool>,
}

impl LivePreviewWorker {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn is_active(&self) -> bool {
        self.is_running.load(Ordering::SeqCst)
    }

    pub fn start(&self, adb_path: PathBuf, device_id: String, tx: Sender<CapturedImage>) {
        if self.is_running.swap(true, Ordering::SeqCst) {
            return;
        }

        let flag = Arc::clone(&self.is_running);
        thread::spawn(move || {
            while flag.load(Ordering::SeqCst) {
                if let Ok(img) = CaptureAdapter::capture_screen(&adb_path, &device_id)
                    && tx.send(img).is_err()
                {
                    break;
                }
                thread::sleep(Duration::from_millis(150));
            }
            flag.store(false, Ordering::SeqCst);
        });
    }

    pub fn stop(&self) {
        self.is_running.store(false, Ordering::SeqCst);
    }
}
