use crate::app::{AppMessage, AppState};
use crate::ui::theme::Theme;
use eframe::egui::{
    self, Color32, ColorImage, Layout, RichText, TextureHandle, TextureOptions, Ui, Vec2,
};

pub fn render_screenshot_view(
    ui: &mut Ui,
    state: &mut AppState,
    screenshot_texture: &mut Option<TextureHandle>,
    tx: &crossbeam_channel::Sender<AppMessage>,
) {
    ui.vertical_centered(|ui| {
        ui.add_space(8.0);

        // Preview container
        egui::Frame::new()
            .fill(Theme::BG_PANEL)
            .stroke(egui::Stroke::new(1.0_f32, Theme::BORDER))
            .corner_radius(8.0)
            .inner_margin(8)
            .show(ui, |ui| {
                let max_h = (ui.available_height() - 110.0).max(200.0);

                if let Some(ref img) = state.last_screenshot {
                    let texture = screenshot_texture.get_or_insert_with(|| {
                        let color_img =
                            ColorImage::from_rgba_unmultiplied([img.width, img.height], &img.rgba);
                        ui.ctx().load_texture(
                            "current_screenshot",
                            color_img,
                            TextureOptions::LINEAR,
                        )
                    });

                    let aspect = img.width as f32 / img.height as f32;
                    let target_h = max_h.min(500.0);
                    let target_w = target_h * aspect;

                    ui.image((texture.id(), Vec2::new(target_w, target_h)));
                } else {
                    ui.allocate_ui_with_layout(
                        Vec2::new(280.0, max_h.min(450.0)),
                        Layout::centered_and_justified(egui::Direction::TopDown),
                        |ui| {
                            ui.label(
                                RichText::new(
                                    "Chưa có ảnh chụp\nBấm nút bên dưới hoặc phím Space để chụp",
                                )
                                .size(13.0)
                                .color(Theme::TEXT_SECONDARY),
                            );
                        },
                    );
                }
            });

        ui.add_space(8.0);

        // Copy button if screenshot is present
        if state.last_screenshot.is_some() {
            if ui
                .button(RichText::new("📋 Sao chép lại vào Clipboard").size(12.5))
                .clicked()
            {
                let _ = tx.send(AppMessage::CopyScreenshotToClipboard);
            }
            ui.add_space(6.0);
        }

        // Primary action button
        let btn_text = if state.is_capturing {
            "⏳ Đang chụp màn hình..."
        } else {
            "📸 Chụp Màn Hình (Space)"
        };

        let btn = egui::Button::new(
            RichText::new(btn_text)
                .size(15.0)
                .color(Color32::WHITE)
                .strong(),
        )
        .fill(Theme::ACCENT)
        .min_size(Vec2::new(320.0, 40.0))
        .corner_radius(6.0);

        if ui
            .add_enabled(
                !state.is_capturing && state.selected_device_id.is_some(),
                btn,
            )
            .clicked()
        {
            let _ = tx.send(AppMessage::TakeScreenshot);
        }

        ui.add_space(8.0);

        // Options row
        ui.horizontal(|ui| {
            ui.checkbox(&mut state.auto_copy_clipboard, "Mặc định vào Clipboard");
            ui.add_space(14.0);
            ui.checkbox(&mut state.auto_save_desktop, "Lưu ở Desktop");
            ui.add_space(14.0);
            ui.checkbox(&mut state.auto_capture_on_launch, "Tự chụp khi mở");
        });
    });
}
