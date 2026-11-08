use adb_studio::adapters::LogcatAdapter;
use adb_studio::domain::LogLevel;

#[test]
fn test_parse_threadtime_logcat_line() {
    let line = "11-08 15:30:45.123  1234  5678 D ActivityManager: Displayed com.example.app/.MainActivity: +120ms";
    let entry = LogcatAdapter::parse_line(1, line).expect("Should parse threadtime log");

    assert_eq!(entry.id, 1);
    assert_eq!(entry.timestamp, "11-08 15:30:45.123");
    assert_eq!(entry.pid, "1234");
    assert_eq!(entry.tid, "5678");
    assert_eq!(entry.level, LogLevel::Debug);
    assert_eq!(entry.tag, "ActivityManager");
    assert_eq!(
        entry.message,
        "Displayed com.example.app/.MainActivity: +120ms"
    );
}

#[test]
fn test_parse_beginning_marker_ignored() {
    let line = "--------- beginning of main";
    assert!(LogcatAdapter::parse_line(2, line).is_none());
}
