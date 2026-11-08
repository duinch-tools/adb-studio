use super::messages::AppMessage;
use super::state::AppState;
use crate::adapters::{
    AdbCli, CaptureAdapter, CapturedImage, ClipboardAdapter, DeviceAdapter, LivePreviewWorker,
    LogcatAdapter, RecorderAdapter,
};
use crate::domain::LogEntry;
use crossbeam_channel::{Receiver, Sender};
use std::sync::Arc;

pub struct AppController {
    pub msg_tx: Sender<AppMessage>,
    pub msg_rx: Receiver<AppMessage>,
    preview_tx: Sender<CapturedImage>,
    preview_rx: Receiver<CapturedImage>,
    logcat_tx: Sender<LogEntry>,
    logcat_rx: Receiver<LogEntry>,

    live_preview: Arc<LivePreviewWorker>,
    recorder: RecorderAdapter,
    logcat: Arc<LogcatAdapter>,
}

impl Default for AppController {
    fn default() -> Self {
        Self::new()
    }
}

impl AppController {
    pub fn new() -> Self {
        let (msg_tx, msg_rx) = crossbeam_channel::unbounded();
        let (preview_tx, preview_rx) = crossbeam_channel::bounded(2);
        let (logcat_tx, logcat_rx) = crossbeam_channel::bounded(1000);

        Self {
            msg_tx,
            msg_rx,
            preview_tx,
            preview_rx,
            logcat_tx,
            logcat_rx,
            live_preview: Arc::new(LivePreviewWorker::new()),
            recorder: RecorderAdapter::new(),
            logcat: Arc::new(LogcatAdapter::new()),
        }
    }

    pub fn init(&mut self, state: &mut AppState) {
        state.adb_path = AdbCli::find_adb();
        if state.adb_path.is_none() {
            state.status_message =
                "ADB command not found! Please install Android platform-tools".to_string();
            state.is_error = true;
        } else {
            self.refresh_devices(state);
        }
    }

    pub fn refresh_devices(&self, state: &mut AppState) {
        let Some(adb) = state.adb_path.clone() else {
            return;
        };
        let tx = self.msg_tx.clone();
        state.status_message = "Searching for ADB devices...".to_string();
        state.is_error = false;

        std::thread::spawn(move || {
            let res = DeviceAdapter::list_devices(&adb);
            let _ = tx.send(AppMessage::DevicesLoaded(res));
        });
    }

    pub fn take_screenshot(&self, state: &mut AppState) {
        let Some(adb) = state.adb_path.clone() else {
            return;
        };
        let Some(dev_id) = state.selected_device_id.clone() else {
            state.status_message = "No Android device selected".to_string();
            state.is_error = true;
            return;
        };

        state.is_capturing = true;
        state.status_message = "Capturing screenshot...".to_string();
        let tx = self.msg_tx.clone();

        std::thread::spawn(move || {
            let res = CaptureAdapter::capture_screen(&adb, &dev_id);
            let _ = tx.send(AppMessage::ScreenshotCaptured(res));
        });
    }

    pub fn toggle_live_preview(&mut self, state: &mut AppState) {
        if self.live_preview.is_active() {
            self.live_preview.stop();
            state.live_preview_active = false;
            state.status_message = "Live Preview stopped".to_string();
        } else {
            let Some(adb) = state.adb_path.clone() else {
                return;
            };
            let Some(dev_id) = state.selected_device_id.clone() else {
                return;
            };
            self.live_preview
                .start(adb, dev_id, self.preview_tx.clone());
            state.live_preview_active = true;
            state.status_message = "Live Preview streaming".to_string();
        }
    }

    pub fn toggle_recording(&mut self, state: &mut AppState) {
        let Some(adb) = state.adb_path.clone() else {
            return;
        };
        let Some(dev_id) = state.selected_device_id.clone() else {
            return;
        };

        if self.recorder.is_recording() {
            match self.recorder.stop_recording(&adb, &dev_id) {
                Ok(path) => {
                    state.is_recording = false;
                    state.recording_start = None;
                    state.last_recorded_file = Some(path.clone());
                    state.status_message = format!("Screen recording saved to: {}", path.display());
                    // Stop live preview if it was only started for recording
                    if !state.live_preview_active {
                        self.live_preview.stop();
                    }
                }
                Err(e) => {
                    state.status_message = format!("Error stopping recording: {e}");
                    state.is_error = true;
                }
            }
        } else {
            let bitrate = state.recording_bitrate_mbps;
            match self.recorder.start_recording(&adb, &dev_id, bitrate) {
                Ok(_) => {
                    state.is_recording = true;
                    state.recording_start = Some(chrono::Local::now());
                    state.status_message = "Recording Android screen (REC)...".to_string();
                    // Automatically turn on Live Preview so the user can see what's being recorded!
                    if !self.live_preview.is_active() {
                        self.live_preview
                            .start(adb, dev_id, self.preview_tx.clone());
                        state.live_preview_active = true;
                    }
                }
                Err(e) => {
                    state.status_message = format!("Failed to start screen recording: {e}");
                    state.is_error = true;
                }
            }
        }
    }

    pub fn start_logcat_stream(&mut self, state: &AppState) {
        let Some(adb) = state.adb_path.clone() else {
            return;
        };
        let Some(dev_id) = state.selected_device_id.clone() else {
            return;
        };
        self.logcat.stop();
        self.logcat.start(adb, dev_id, self.logcat_tx.clone());
    }

    pub fn poll_updates(&mut self, state: &mut AppState) {
        // 1. Drain preview frames
        while let Ok(frame) = self.preview_rx.try_recv() {
            state.preview_frame = Some(frame);
        }

        // 2. Drain logcat entries
        let mut count = 0;
        while let Ok(entry) = self.logcat_rx.try_recv() {
            if !state.logcat_paused {
                if state.logs.len() >= state.max_log_capacity {
                    state.logs.drain(0..100);
                }
                state.logs.push(entry);
                count += 1;
                if count > 200 {
                    break;
                }
            }
        }

        // 3. Drain app messages
        while let Ok(msg) = self.msg_rx.try_recv() {
            self.handle_message(msg, state);
        }
    }

    fn handle_message(&mut self, msg: AppMessage, state: &mut AppState) {
        match msg {
            AppMessage::RefreshDevices => self.refresh_devices(state),
            AppMessage::DevicesLoaded(res) => match res {
                Ok(devs) => {
                    state.devices = devs;
                    if state.selected_device_id.is_none() && !state.devices.is_empty() {
                        state.selected_device_id = Some(state.devices[0].id.clone());
                    }
                    state.status_message =
                        format!("Connected to {} device(s)", state.devices.len());
                    state.is_error = false;
                    if state.auto_capture_on_launch
                        && state.last_screenshot.is_none()
                        && state.selected_device_id.is_some()
                    {
                        self.take_screenshot(state);
                    }
                }
                Err(err) => {
                    state.status_message = err;
                    state.is_error = true;
                }
            },
            AppMessage::SelectDevice(id) => {
                state.selected_device_id = Some(id);
                self.start_logcat_stream(state);
            }
            AppMessage::SwitchTab(tab) => {
                state.active_tab = tab;
                if tab == crate::domain::AppTab::Logcat && !self.logcat.is_active() {
                    self.start_logcat_stream(state);
                }
            }
            AppMessage::TakeScreenshot => self.take_screenshot(state),
            AppMessage::ScreenshotCaptured(res) => {
                state.is_capturing = false;
                match res {
                    Ok(img) => {
                        if state.auto_copy_clipboard {
                            let _ =
                                ClipboardAdapter::copy_rgba_image(img.width, img.height, &img.rgba);
                        }
                        state.status_message =
                            "Screenshot captured & copied to Clipboard".to_string();
                        state.is_error = false;
                        state.last_screenshot = Some(img);
                    }
                    Err(e) => {
                        state.status_message = e;
                        state.is_error = true;
                    }
                }
            }
            AppMessage::CopyScreenshotToClipboard => {
                if let Some(ref img) = state.last_screenshot {
                    let _ = ClipboardAdapter::copy_rgba_image(img.width, img.height, &img.rgba);
                    state.status_message = "Screenshot copied to Clipboard!".to_string();
                }
            }
            AppMessage::ToggleLivePreview => self.toggle_live_preview(state),
            AppMessage::LivePreviewFrameReceived(frame) => state.preview_frame = Some(frame),
            AppMessage::ToggleRecording => self.toggle_recording(state),
            AppMessage::RecordingStarted(_res) => { /* handled */ }
            AppMessage::RecordingStopped(_res) => { /* handled */ }
            AppMessage::LogcatEntryReceived(entry) => {
                if !state.logcat_paused {
                    state.logs.push(entry);
                }
            }
            AppMessage::ToggleLogcatPause => {
                state.logcat_paused = !state.logcat_paused;
            }
            AppMessage::ClearLogcat => {
                state.logs.clear();
            }
            AppMessage::CopyLogcat => {
                let text = state
                    .logs
                    .iter()
                    .map(|l| {
                        format!(
                            "{} {} {}/{} {}: {}",
                            l.timestamp,
                            l.pid,
                            l.level.short_tag(),
                            l.tag,
                            l.tid,
                            l.message
                        )
                    })
                    .collect::<Vec<_>>()
                    .join("\n");
                let _ = ClipboardAdapter::copy_text(&text);
                state.status_message = "All logs copied to Clipboard!".to_string();
            }
        }
    }
}
