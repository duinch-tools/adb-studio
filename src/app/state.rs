use crate::adapters::CapturedImage;
use crate::domain::{AdbDevice, AppTab, LogEntry, LogLevel};
use chrono::{DateTime, Local};
use std::path::PathBuf;

pub struct AppState {
    pub adb_path: Option<PathBuf>,
    pub devices: Vec<AdbDevice>,
    pub selected_device_id: Option<String>,
    pub active_tab: AppTab,
    pub status_message: String,
    pub is_error: bool,

    // Screenshot
    pub last_screenshot: Option<CapturedImage>,
    pub auto_copy_clipboard: bool,
    pub auto_save_desktop: bool,
    pub auto_capture_on_launch: bool,
    pub is_capturing: bool,

    // Recording & Live Preview
    pub is_recording: bool,
    pub live_preview_active: bool,
    pub recording_start: Option<DateTime<Local>>,
    pub recording_bitrate_mbps: u32,
    pub preview_frame: Option<CapturedImage>,
    pub last_recorded_file: Option<PathBuf>,

    // Logcat
    pub logs: Vec<LogEntry>,
    pub logcat_min_level: LogLevel,
    pub logcat_search: String,
    pub logcat_package: String,
    pub logcat_tag: String,
    pub logcat_paused: bool,
    pub logcat_auto_scroll: bool,
    pub max_log_capacity: usize,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            adb_path: None,
            devices: Vec::new(),
            selected_device_id: None,
            active_tab: AppTab::Screenshot,
            status_message: "Khởi tạo ADB Studio...".to_string(),
            is_error: false,

            last_screenshot: None,
            auto_copy_clipboard: true,
            auto_save_desktop: true,
            auto_capture_on_launch: true,
            is_capturing: false,

            is_recording: false,
            live_preview_active: false,
            recording_start: None,
            recording_bitrate_mbps: 12,
            preview_frame: None,
            last_recorded_file: None,

            logs: Vec::with_capacity(3000),
            logcat_min_level: LogLevel::Verbose,
            logcat_search: String::new(),
            logcat_package: String::new(),
            logcat_tag: String::new(),
            logcat_paused: false,
            logcat_auto_scroll: true,
            max_log_capacity: 5000,
        }
    }
}
