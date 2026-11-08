use crate::app::AppState;
use crate::ui::theme::Theme;
use eframe::egui::{self, Layout, RichText, Sense, Ui, Vec2};

pub fn render_footer(ui: &mut Ui, state: &AppState) {
    ui.horizontal(|ui| {
        ui.spacing_mut().item_spacing.x = 8.0;

        let (dot_color, text_color) = if state.is_error {
            (Theme::ACCENT_REC, Theme::ACCENT_REC)
        } else {
            (Theme::ACCENT, Theme::TEXT_SECONDARY)
        };

        let (dot_rect, _) = ui.allocate_exact_size(Vec2::new(8.0, 8.0), Sense::hover());
        ui.painter()
            .circle_filled(dot_rect.center(), 3.5, dot_color);

        ui.label(
            RichText::new(&state.status_message)
                .size(11.5)
                .color(text_color),
        );

        ui.with_layout(Layout::right_to_left(egui::Align::Center), |ui| {
            ui.label(
                RichText::new("v1.0.0 (Rust Edition) · duinch-tools")
                    .size(11.0)
                    .color(Theme::TEXT_SECONDARY),
            );
        });
    });
}
