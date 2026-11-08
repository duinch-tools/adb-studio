use crate::app::AppState;
use crate::ui::theme::Theme;
use eframe::egui::{self, Layout, RichText, Ui};

pub fn render_footer(ui: &mut Ui, state: &AppState) {
    egui::Frame::new()
        .fill(Theme::BG_PANEL)
        .inner_margin(egui::Margin::symmetric(14, 6))
        .show(ui, |ui| {
            ui.horizontal(|ui| {
                let color = if state.is_error {
                    Theme::ACCENT_REC
                } else {
                    Theme::TEXT_SECONDARY
                };

                let prefix = if state.is_error { "❌ " } else { "ℹ️ " };
                ui.label(
                    RichText::new(format!("{prefix}{}", state.status_message))
                        .size(11.5)
                        .color(color),
                );

                ui.with_layout(Layout::right_to_left(egui::Align::Center), |ui| {
                    ui.label(
                        RichText::new("v1.0.0 (Rust Edition) · duinch-tools")
                            .size(11.0)
                            .color(Theme::TEXT_SECONDARY),
                    );
                });
            });
        });
}
