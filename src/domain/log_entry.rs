use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub enum LogLevel {
    Verbose = 2,
    Debug = 3,
    Info = 4,
    Warn = 5,
    Error = 6,
    Assert = 7,
}

impl LogLevel {
    pub const ALL: [LogLevel; 6] = [
        LogLevel::Verbose,
        LogLevel::Debug,
        LogLevel::Info,
        LogLevel::Warn,
        LogLevel::Error,
        LogLevel::Assert,
    ];

    pub fn as_str(&self) -> &'static str {
        match self {
            LogLevel::Verbose => "Verbose",
            LogLevel::Debug => "Debug",
            LogLevel::Info => "Info",
            LogLevel::Warn => "Warn",
            LogLevel::Error => "Error",
            LogLevel::Assert => "Assert",
        }
    }

    pub fn short_tag(&self) -> &'static str {
        match self {
            LogLevel::Verbose => "V",
            LogLevel::Debug => "D",
            LogLevel::Info => "I",
            LogLevel::Warn => "W",
            LogLevel::Error => "E",
            LogLevel::Assert => "A",
        }
    }

    pub fn from_tag(tag: &str) -> Self {
        match tag.trim().to_uppercase().as_str() {
            "V" => LogLevel::Verbose,
            "D" => LogLevel::Debug,
            "I" => LogLevel::Info,
            "W" => LogLevel::Warn,
            "E" => LogLevel::Error,
            "A" | "F" => LogLevel::Assert,
            _ => LogLevel::Verbose,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LogEntry {
    pub id: u64,
    pub timestamp: String,
    pub pid: String,
    pub tid: String,
    pub level: LogLevel,
    pub tag: String,
    pub message: String,
}
