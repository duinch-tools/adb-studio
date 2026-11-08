use adb_studio::domain::{AdbDevice, AppTab, LogLevel};

#[test]
fn test_adb_device_display_name() {
    let dev = AdbDevice::new("emulator-5554", "Pixel 7 Pro");
    assert_eq!(dev.display_name(), "Pixel 7 Pro (emulator-5554)");

    let dev_empty_model = AdbDevice::new("192.168.1.10:5555", "");
    assert_eq!(dev_empty_model.display_name(), "192.168.1.10:5555");
}

#[test]
fn test_log_level_parsing_and_order() {
    assert_eq!(LogLevel::from_tag("V"), LogLevel::Verbose);
    assert_eq!(LogLevel::from_tag("D"), LogLevel::Debug);
    assert_eq!(LogLevel::from_tag("I"), LogLevel::Info);
    assert_eq!(LogLevel::from_tag("W"), LogLevel::Warn);
    assert_eq!(LogLevel::from_tag("E"), LogLevel::Error);
    assert_eq!(LogLevel::from_tag("A"), LogLevel::Assert);
    assert_eq!(LogLevel::from_tag("F"), LogLevel::Assert);

    assert!(LogLevel::Error > LogLevel::Warn);
    assert!(LogLevel::Warn > LogLevel::Info);
    assert!(LogLevel::Info > LogLevel::Debug);
    assert!(LogLevel::Debug > LogLevel::Verbose);
}

#[test]
fn test_app_tab_attributes() {
    assert_eq!(AppTab::Screenshot.short_name(), "Screenshot");
    assert_eq!(AppTab::Recording.short_name(), "Recording");
    assert_eq!(AppTab::Logcat.short_name(), "Logcat");
}
