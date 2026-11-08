use crate::adapters::CapturedImage;
use crate::domain::{AdbDevice, AppTab, LogEntry};
use std::path::PathBuf;

#[derive(Debug)]
pub enum AppMessage {
    RefreshDevices,
    DevicesLoaded(Result<Vec<AdbDevice>, String>),
    SelectDevice(String),
    SwitchTab(AppTab),

    TakeScreenshot,
    ScreenshotCaptured(Result<CapturedImage, String>),
    CopyScreenshotToClipboard,

    ToggleLivePreview,
    LivePreviewFrameReceived(CapturedImage),

    ToggleRecording,
    RecordingStarted(Result<PathBuf, String>),
    RecordingStopped(Result<PathBuf, String>),

    LogcatEntryReceived(LogEntry),
    ToggleLogcatPause,
    ClearLogcat,
    CopyLogcat,
}
