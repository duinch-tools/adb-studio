use crate::domain::LogLevel;
use eframe::egui::{Color32, Visuals};

pub struct Theme;

impl Theme {
    pub const BG_VOID: Color32 = Color32::from_rgb(26, 27, 30);
    pub const BG_PANEL: Color32 = Color32::from_rgb(34, 35, 38);
    pub const BG_CARD: Color32 = Color32::from_rgb(42, 44, 49);
    pub const BORDER: Color32 = Color32::from_rgb(58, 60, 67);

    pub const ACCENT: Color32 = Color32::from_rgb(53, 116, 240);
    pub const ACCENT_ACTIVE: Color32 = Color32::from_rgb(76, 138, 255);
    pub const ACCENT_REC: Color32 = Color32::from_rgb(235, 60, 60);

    pub const TEXT_PRIMARY: Color32 = Color32::from_rgb(228, 230, 235);
    pub const TEXT_SECONDARY: Color32 = Color32::from_rgb(145, 148, 160);

    pub fn log_level_color(level: LogLevel) -> Color32 {
        match level {
            LogLevel::Verbose => Color32::from_rgb(165, 168, 178),
            LogLevel::Debug => Color32::from_rgb(88, 157, 246),
            LogLevel::Info => Color32::from_rgb(89, 198, 134),
            LogLevel::Warn => Color32::from_rgb(245, 185, 62),
            LogLevel::Error => Color32::from_rgb(249, 90, 90),
            LogLevel::Assert => Color32::from_rgb(190, 115, 245),
        }
    }

    pub fn apply_visuals(ctx: &eframe::egui::Context) {
        let mut visuals = Visuals::dark();
        visuals.panel_fill = Self::BG_VOID;
        visuals.window_fill = Self::BG_VOID;
        visuals.override_text_color = Some(Self::TEXT_PRIMARY);
        ctx.set_visuals(visuals);
    }
}
