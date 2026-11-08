use crate::domain::LogLevel;
use eframe::egui::{
    Color32, CornerRadius, FontData, FontDefinitions, FontFamily, FontId, Stroke, TextStyle, Vec2,
    Visuals,
};
use std::sync::Arc;

pub struct Theme;

impl Theme {
    pub const BG_VOID: Color32 = Color32::from_rgb(18, 19, 23);
    pub const BG_PANEL: Color32 = Color32::from_rgb(26, 28, 34);
    pub const BG_CARD: Color32 = Color32::from_rgb(36, 39, 47);
    pub const BG_CARD_HOVER: Color32 = Color32::from_rgb(48, 52, 62);
    pub const BORDER: Color32 = Color32::from_rgb(54, 58, 70);

    pub const ACCENT: Color32 = Color32::from_rgb(59, 130, 246);
    pub const ACCENT_ACTIVE: Color32 = Color32::from_rgb(96, 165, 250);
    pub const ACCENT_REC: Color32 = Color32::from_rgb(239, 68, 68);
    pub const SUCCESS: Color32 = Color32::from_rgb(34, 197, 94);

    pub const TEXT_PRIMARY: Color32 = Color32::from_rgb(241, 243, 247);
    pub const TEXT_SECONDARY: Color32 = Color32::from_rgb(156, 163, 175);

    pub fn semibold_family() -> FontFamily {
        FontFamily::Name("InterSemiBold".into())
    }

    pub fn log_level_color(level: LogLevel) -> Color32 {
        match level {
            LogLevel::Verbose => Color32::from_rgb(156, 163, 175),
            LogLevel::Debug => Color32::from_rgb(96, 165, 250),
            LogLevel::Info => Color32::from_rgb(74, 222, 128),
            LogLevel::Warn => Color32::from_rgb(251, 191, 36),
            LogLevel::Error => Color32::from_rgb(248, 113, 113),
            LogLevel::Assert => Color32::from_rgb(192, 132, 252),
        }
    }

    pub fn apply_fonts(ctx: &eframe::egui::Context) {
        let mut fonts = FontDefinitions::default();

        fonts.font_data.insert(
            "InterRegular".to_owned(),
            Arc::new(FontData::from_static(include_bytes!(
                "../../Resources/fonts/Inter-Regular.otf"
            ))),
        );
        fonts.font_data.insert(
            "InterSemiBold".to_owned(),
            Arc::new(FontData::from_static(include_bytes!(
                "../../Resources/fonts/Inter-SemiBold.otf"
            ))),
        );
        fonts.font_data.insert(
            "JetBrainsMono".to_owned(),
            Arc::new(FontData::from_static(include_bytes!(
                "../../Resources/fonts/JetBrainsMono-Medium.ttf"
            ))),
        );

        let fallback_proportional = fonts
            .families
            .get(&FontFamily::Proportional)
            .cloned()
            .unwrap_or_default();

        if let Some(family) = fonts.families.get_mut(&FontFamily::Proportional) {
            family.insert(0, "InterRegular".to_owned());
        }

        let mut semibold_chain = vec!["InterSemiBold".to_owned(), "InterRegular".to_owned()];
        semibold_chain.extend(fallback_proportional);
        fonts
            .families
            .insert(Self::semibold_family(), semibold_chain);

        if let Some(family) = fonts.families.get_mut(&FontFamily::Monospace) {
            family.insert(0, "JetBrainsMono".to_owned());
        }

        ctx.set_fonts(fonts);
    }

    pub fn apply_visuals(ctx: &eframe::egui::Context) {
        let mut style = (*ctx.style()).clone();

        style.text_styles.insert(
            TextStyle::Heading,
            FontId::new(15.5, Self::semibold_family()),
        );
        style
            .text_styles
            .insert(TextStyle::Body, FontId::new(13.0, FontFamily::Proportional));
        style.text_styles.insert(
            TextStyle::Button,
            FontId::new(13.0, Self::semibold_family()),
        );
        style.text_styles.insert(
            TextStyle::Small,
            FontId::new(11.5, FontFamily::Proportional),
        );
        style.text_styles.insert(
            TextStyle::Monospace,
            FontId::new(12.0, FontFamily::Monospace),
        );

        style.spacing.button_padding = Vec2::new(12.0, 6.0);
        style.spacing.item_spacing = Vec2::new(8.0, 8.0);
        style.spacing.interact_size = Vec2::new(40.0, 28.0);

        let mut visuals = Visuals::dark();
        visuals.dark_mode = true;
        visuals.panel_fill = Self::BG_VOID;
        visuals.window_fill = Self::BG_PANEL;
        visuals.extreme_bg_color = Self::BG_VOID;
        visuals.faint_bg_color = Self::BG_PANEL;
        visuals.override_text_color = Some(Self::TEXT_PRIMARY);
        visuals.selection.bg_fill = Self::ACCENT;
        visuals.selection.stroke = Stroke::new(1.0_f32, Color32::WHITE);

        let radius = CornerRadius::same(6);
        visuals.widgets.noninteractive.bg_fill = Self::BG_PANEL;
        visuals.widgets.noninteractive.bg_stroke = Stroke::new(1.0_f32, Self::BORDER);
        visuals.widgets.noninteractive.corner_radius = radius;

        visuals.widgets.inactive.bg_fill = Self::BG_CARD;
        visuals.widgets.inactive.weak_bg_fill = Self::BG_CARD;
        visuals.widgets.inactive.bg_stroke = Stroke::new(1.0_f32, Self::BORDER);
        visuals.widgets.inactive.corner_radius = radius;

        visuals.widgets.hovered.bg_fill = Self::BG_CARD_HOVER;
        visuals.widgets.hovered.weak_bg_fill = Self::BG_CARD_HOVER;
        visuals.widgets.hovered.bg_stroke = Stroke::new(1.0_f32, Self::ACCENT_ACTIVE);
        visuals.widgets.hovered.corner_radius = radius;

        visuals.widgets.active.bg_fill = Self::ACCENT;
        visuals.widgets.active.weak_bg_fill = Self::ACCENT;
        visuals.widgets.active.bg_stroke = Stroke::new(1.0_f32, Self::ACCENT_ACTIVE);
        visuals.widgets.active.corner_radius = radius;

        visuals.widgets.open.bg_fill = Self::BG_CARD_HOVER;
        visuals.widgets.open.weak_bg_fill = Self::BG_CARD_HOVER;
        visuals.widgets.open.bg_stroke = Stroke::new(1.0_f32, Self::ACCENT);
        visuals.widgets.open.corner_radius = radius;

        style.visuals = visuals;
        ctx.set_style(style);
    }
}
