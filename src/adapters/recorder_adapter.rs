use super::adb_cli::AdbCli;
use chrono::Local;
use std::path::{Path, PathBuf};
use std::process::{Child, Command};

#[derive(Default)]
pub struct RecorderAdapter {
    process: Option<Child>,
    remote_path: String,
    local_path: PathBuf,
}

impl RecorderAdapter {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn is_recording(&self) -> bool {
        self.process.is_some()
    }

    pub fn start_recording(
        &mut self,
        adb_path: &Path,
        device_id: &str,
        bitrate_mbps: u32,
    ) -> Result<PathBuf, String> {
        if self.is_recording() {
            return Err("Recording is already in progress".into());
        }

        let now = Local::now().format("%Y%m%d_%H%M%S");
        let remote_file = format!("/sdcard/adb_studio_{now}.mp4");

        let local_dir = dirs_fallback_desktop();
        let local_file = local_dir.join(format!("ADB_Record_{now}.mp4"));

        let bitrate_arg = format!("{}M", bitrate_mbps.clamp(2, 30));

        let child = Command::new(adb_path)
            .args([
                "-s",
                device_id,
                "shell",
                "screenrecord",
                "--bit-rate",
                &bitrate_arg,
                &remote_file,
            ])
            .spawn()
            .map_err(|e| format!("Failed to start screenrecord: {e}"))?;

        self.process = Some(child);
        self.remote_path = remote_file;
        self.local_path = local_file.clone();

        Ok(local_file)
    }

    pub fn stop_recording(&mut self, adb_path: &Path, device_id: &str) -> Result<PathBuf, String> {
        if let Some(mut child) = self.process.take() {
            #[cfg(unix)]
            {
                let pid = child.id();
                // Send SIGINT to let screenrecord write mp4 atom cleanly
                let _ = Command::new("kill").args(["-2", &pid.to_string()]).output();
            }
            #[cfg(not(unix))]
            {
                let _ = child.kill();
            }

            let _ = child.wait();
            std::thread::sleep(std::time::Duration::from_millis(500));

            // Pull to local path
            let _ = AdbCli::run_args(
                adb_path,
                &[
                    "-s",
                    device_id,
                    "pull",
                    &self.remote_path,
                    self.local_path.to_str().unwrap_or("."),
                ],
            );

            // Clean remote
            let _ = AdbCli::run_args(
                adb_path,
                &["-s", device_id, "shell", "rm", "-f", &self.remote_path],
            );

            Ok(self.local_path.clone())
        } else {
            Err("No active recording session".into())
        }
    }
}

fn dirs_fallback_desktop() -> PathBuf {
    if let Ok(home) = std::env::var("HOME") {
        let p = PathBuf::from(home).join("Desktop");
        if p.is_dir() {
            return p;
        }
    }
    std::env::temp_dir()
}
