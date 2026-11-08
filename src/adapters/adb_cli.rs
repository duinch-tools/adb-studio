use std::path::{Path, PathBuf};
use std::process::Command;

pub struct AdbCli;

impl AdbCli {
    pub fn find_adb() -> Option<PathBuf> {
        if let Ok(path) = which::which("adb") {
            return Some(path);
        }

        let candidates = [
            "/opt/homebrew/bin/adb",
            "/usr/local/bin/adb",
            "/usr/bin/adb",
        ];

        for c in candidates {
            let p = Path::new(c);
            if p.is_file() {
                return Some(p.to_path_buf());
            }
        }

        if let Ok(home) = std::env::var("HOME") {
            let user_paths = [
                format!("{home}/Library/Android/sdk/platform-tools/adb"),
                format!("{home}/Android/Sdk/platform-tools/adb"),
            ];
            for c in user_paths {
                let p = PathBuf::from(c);
                if p.is_file() {
                    return Some(p);
                }
            }
        }

        #[cfg(target_os = "windows")]
        if let Ok(local_appdata) = std::env::var("LOCALAPPDATA") {
            let win_path =
                PathBuf::from(local_appdata).join("Android\\Sdk\\platform-tools\\adb.exe");
            if win_path.is_file() {
                return Some(win_path);
            }
        }

        None
    }

    pub fn run_args(adb_path: &Path, args: &[&str]) -> Result<String, String> {
        let output = Command::new(adb_path)
            .args(args)
            .output()
            .map_err(|e| format!("Failed to execute adb: {e}"))?;

        if output.status.success() {
            Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
        } else {
            let err = String::from_utf8_lossy(&output.stderr).trim().to_string();
            Err(if err.is_empty() {
                format!("ADB exited with code {:?}", output.status.code())
            } else {
                err
            })
        }
    }
}
