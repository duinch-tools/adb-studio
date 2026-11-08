use crate::app::{AppMessage, AppState};
use crate::ui::theme::Theme;
use eframe::egui::{
    self, Color32, ColorImage, Layout, RichText, TextureHandle, TextureOptions, Ui, Vec2,
};

pub fn render_recorder_view(
    ui: &mut Ui,
    state: &mut AppState,
    preview_texture: &mut Option<TextureHandle>,
    tx: &crossbeam_channel::Sender<AppMessage>,
) {
    ui.vertical_centered(|ui| {
        ui.add_space(8.0);

        // Preview container with Live Texture
        egui::Frame::new()
            .fill(Theme::BG_PANEL)
            .stroke(egui::Stroke::new(1.0_f32, if state.is_recording { Theme::ACCENT_REC } else { Theme::BORDER }))
            .corner_radius(8.0)
            .inner_margin(8)
            .show(ui, |ui| {
                let max_h = (ui.available_height() - 140.0).max(200.0);

                if let Some(ref img) = state.preview_frame {
                    let color_img = ColorImage::from_rgba_unmultiplied(
                        [img.width, img.height],
                        &img.rgba,
                    );
                    let texture = preview_texture.insert(ui.ctx().load_texture(
                        "live_preview_frame",
                        color_img,
                        TextureOptions::LINEAR,
                    ));

                    let aspect = img.width as f32 / img.height as f32;
                    let target_h = max_h.min(500.0);
                    let target_w = target_h * aspect;

                    ui.vertical_centered(|ui| {
                        // Live badge
                        ui.horizontal(|ui| {
                            if state.is_recording {
                                let elapsed = if let Some(start) = state.recording_start {
                                    let sec = (chrono::Local::now() - start).num_seconds().max(0);
                                    format!("{:02}:{:02}", sec / 60, sec % 60)
                                } else {
                                    "00:00".to_string()
                                };
                                ui.label(RichText::new(format!("🔴 REC [{elapsed}] - RECORDING")).color(Theme::ACCENT_REC).strong());
                            } else {
                                ui.label(RichText::new("🟢 LIVE PREVIEW").color(Color32::from_rgb(89, 198, 134)).size(11.5));
                            }
                        });

                        ui.image((texture.id(), Vec2::new(target_w, target_h)));
                    });
                } else {
                    ui.allocate_ui_with_layout(
                        Vec2::new(300.0, max_h.min(450.0)),
                        Layout::centered_and_justified(egui::Direction::TopDown),
                        |ui| {
                            ui.label(
                                RichText::new("Live Preview is off\nClick below to start live preview or record video")
                                    .size(13.0)
                                    .color(Theme::TEXT_SECONDARY),
                            );
                        },
                    );
                }
            });

        ui.add_space(8.0);

        // Action controls
        ui.horizontal(|ui| {
            // Live Preview Toggle
            let preview_btn_text = if state.live_preview_active {
                "⏹ Stop Live Preview"
            } else {
                "👁 Start Live Preview"
            };
            if ui.button(RichText::new(preview_btn_text).size(13.0)).clicked() {
                let _ = tx.send(AppMessage::ToggleLivePreview);
            }

            ui.add_space(8.0);

            // Record Button
            let (rec_text, rec_color) = if state.is_recording {
                ("⏹ STOP RECORDING & SAVE MP4", Theme::ACCENT_REC)
            } else {
                ("🔴 START RECORDING (REC)", Theme::ACCENT)
            };

            let rec_btn = egui::Button::new(RichText::new(rec_text).size(14.0).color(Color32::WHITE).strong())
                .fill(rec_color)
                .min_size(Vec2::new(240.0, 36.0))
                .corner_radius(6.0);

            if ui.add_enabled(state.selected_device_id.is_some(), rec_btn).clicked() {
                let _ = tx.send(AppMessage::ToggleRecording);
            }
        });

        ui.add_space(8.0);

        // Quality settings & info
        ui.horizontal(|ui| {
            ui.label(RichText::new("Bitrate:").size(12.0).color(Theme::TEXT_SECONDARY));
            egui::ComboBox::from_id_salt("bitrate_select")
                .selected_text(format!("{} Mbps", state.recording_bitrate_mbps))
                .show_ui(ui, |ui| {
                    ui.selectable_value(&mut state.recording_bitrate_mbps, 6, "6 Mbps (Low)");
                    ui.selectable_value(&mut state.recording_bitrate_mbps, 12, "12 Mbps (Standard)");
                    ui.selectable_value(&mut state.recording_bitrate_mbps, 16, "16 Mbps (High)");
                    ui.selectable_value(&mut state.recording_bitrate_mbps, 24, "24 Mbps (Ultra)");
                });

            if let Some(ref path) = state.last_recorded_file {
                ui.add_space(14.0);
                ui.label(RichText::new(format!("Saved: {}", path.file_name().and_then(|n| n.to_str()).unwrap_or(""))).size(11.5).color(Color32::from_rgb(89, 198, 134)));
            }
        });
    });
}
