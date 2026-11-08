use super::adb_cli::AdbCli;
use crate::domain::AdbDevice;
use std::path::Path;

pub struct DeviceAdapter;

impl DeviceAdapter {
    pub fn list_devices(adb_path: &Path) -> Result<Vec<AdbDevice>, String> {
        let raw = AdbCli::run_args(adb_path, &["devices", "-l"])?;
        let mut devices = Vec::new();

        for line in raw.lines().skip(1) {
            let line = line.trim();
            if line.is_empty() {
                continue;
            }

            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() < 2 {
                continue;
            }

            let id = parts[0].to_string();
            let state = parts[1];
            if state != "device" {
                continue;
            }

            let mut model = String::new();
            for part in &parts[2..] {
                if let Some(m) = part.strip_prefix("model:") {
                    model = m.replace('_', " ");
                    break;
                }
            }

            if model.is_empty() {
                let prop_res = AdbCli::run_args(
                    adb_path,
                    &["-s", &id, "shell", "getprop", "ro.product.model"],
                );
                if let Ok(prop) = prop_res {
                    model = prop.trim().to_string();
                }
            }

            if model.is_empty() {
                model = "Android Device".to_string();
            }

            devices.push(AdbDevice::new(id, model));
        }

        Ok(devices)
    }
}
