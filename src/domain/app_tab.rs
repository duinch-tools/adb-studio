use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, Serialize, Deserialize)]
pub enum AppTab {
    #[default]
    Screenshot,
    Recording,
    Logcat,
}

impl AppTab {
    pub const ALL: [AppTab; 3] = [AppTab::Screenshot, AppTab::Recording, AppTab::Logcat];

    pub fn title(&self) -> &'static str {
        match self {
            AppTab::Screenshot => "Screenshot",
            AppTab::Recording => "Screen Recording (Live Preview)",
            AppTab::Logcat => "Logcat Studio",
        }
    }

    pub fn short_name(&self) -> &'static str {
        match self {
            AppTab::Screenshot => "Screenshot",
            AppTab::Recording => "Recording",
            AppTab::Logcat => "Logcat",
        }
    }

    pub fn icon(&self) -> &'static str {
        match self {
            AppTab::Screenshot => "📷",
            AppTab::Recording => "🎥",
            AppTab::Logcat => "☰",
        }
    }
}
