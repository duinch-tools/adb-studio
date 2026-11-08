use crate::app::{AppMessage, AppState};
use crate::ui::theme::Theme;
use eframe::egui::{
    self, Align, Color32, ColorImage, Layout, Margin, RichText, Stroke, TextureHandle,
    TextureOptions, Ui, Vec2,
};

pub fn render_screenshot_view(
    ui: &mut Ui,
    state: &mut AppState,
    screenshot_texture: &mut Option<TextureHandle>,
    tx: &crossbeam_channel::Sender<AppMessage>,
) {
    ui.vertical_centered(|ui| {
        let max_h = (ui.available_height() - 108.0).max(200.0);

        // Preview Stage Card
        egui::Frame::new()
            .fill(Theme::BG_PANEL)
            .stroke(Stroke::new(1.0_f32, Theme::BORDER))
            .corner_radius(10.0)
            .inner_margin(Margin::same(12))
            .show(ui, |ui| {
                if let Some(ref img) = state.last_screenshot {
                    let color_img =
                        ColorImage::from_rgba_unmultiplied([img.width, img.height], &img.rgba);
                    let texture = screenshot_texture.insert(ui.ctx().load_texture(
                        "current_screenshot",
                        color_img,
                        TextureOptions::LINEAR,
                    ));

                    let aspect = img.width as f32 / img.height as f32;
                    let target_h = (max_h - 24.0).clamp(180.0, 520.0);
                    let target_w = target_h * aspect;

                    ui.allocate_ui_with_layout(
                        Vec2::new(target_w.max(280.0), target_h),
                        Layout::centered_and_justified(egui::Direction::TopDown),
                        |ui| {
                            ui.image((texture.id(), Vec2::new(target_w, target_h)));
                        },
                    );
                } else {
                    let placeholder_h = (max_h - 24.0).clamp(200.0, 440.0);
                    ui.allocate_ui_with_layout(
                        Vec2::new(320.0, placeholder_h),
                        Layout::top_down(Align::Center),
                        |ui| {
                            ui.add_space(placeholder_h * 0.38);
                            ui.label(
                                RichText::new("No Screenshot Captured")
                                    .family(Theme::semibold_family())
                                    .size(14.5)
                                    .color(Theme::TEXT_PRIMARY),
                            );
                            ui.add_space(6.0);
                            ui.label(
                                RichText::new(
                                    "Click Capture below or press Space to grab the screen",
                                )
                                .size(12.5)
                                .color(Theme::TEXT_SECONDARY),
                            );
                        },
                    );
                }
            });

        ui.add_space(12.0);

        // Centered Action Button Deck (444px total width: 256 + 12 + 176)
        ui.allocate_ui_with_layout(
            Vec2::new(444.0, 38.0),
            Layout::left_to_right(Align::Center),
            |ui| {
                ui.spacing_mut().item_spacing.x = 12.0;

                let capture_text = if state.is_capturing {
                    "⏳  Capturing Screenshot..."
                } else {
                    "📷  Capture Screenshot (Space)"
                };

                let capture_btn = egui::Button::new(
                    RichText::new(capture_text)
                        .family(Theme::semibold_family())
                        .size(13.5)
                        .color(Color32::WHITE),
                )
                .fill(Theme::ACCENT)
                .stroke(Stroke::NONE)
                .min_size(Vec2::new(256.0, 38.0))
                .corner_radius(8.0);

                if ui
                    .add_enabled(
                        !state.is_capturing && state.selected_device_id.is_some(),
                        capture_btn,
                    )
                    .clicked()
                {
                    let _ = tx.send(AppMessage::TakeScreenshot);
                }

                let copy_btn = egui::Button::new(
                    RichText::new("📋  Copy to Clipboard")
                        .family(Theme::semibold_family())
                        .size(13.0)
                        .color(Theme::TEXT_PRIMARY),
                )
                .fill(Theme::BG_CARD)
                .stroke(Stroke::new(1.0_f32, Theme::BORDER))
                .min_size(Vec2::new(176.0, 38.0))
                .corner_radius(8.0);

                if ui
                    .add_enabled(state.last_screenshot.is_some(), copy_btn)
                    .clicked()
                {
                    let _ = tx.send(AppMessage::CopyScreenshotToClipboard);
                }
            },
        );

        ui.add_space(8.0);

        // Centered Options Pill Bar (matching 444px width)
        ui.allocate_ui_with_layout(
            Vec2::new(444.0, 34.0),
            Layout::top_down(Align::Center),
            |ui| {
                egui::Frame::new()
                    .fill(Theme::BG_PANEL)
                    .stroke(Stroke::new(1.0_f32, Theme::BORDER))
                    .corner_radius(8.0)
                    .inner_margin(Margin::symmetric(16, 6))
                    .show(ui, |ui| {
                        ui.set_min_width(410.0);
                        ui.horizontal(|ui| {
                            ui.spacing_mut().item_spacing.x = 18.0;
                            ui.checkbox(&mut state.auto_copy_clipboard, "Auto-copy to Clipboard");
                            ui.checkbox(&mut state.auto_save_desktop, "Save to Desktop");
                            ui.checkbox(&mut state.auto_capture_on_launch, "Capture on launch");
                        });
                    });
            },
        );
    });
}
