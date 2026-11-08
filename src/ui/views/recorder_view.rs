use crate::app::{AppMessage, AppState};
use crate::ui::theme::Theme;
use eframe::egui::{
    self, Align, Color32, ColorImage, Layout, Margin, RichText, Sense, Stroke, TextureHandle,
    TextureOptions, Ui, Vec2,
};

pub fn render_recorder_view(
    ui: &mut Ui,
    state: &mut AppState,
    preview_texture: &mut Option<TextureHandle>,
    tx: &crossbeam_channel::Sender<AppMessage>,
) {
    ui.vertical_centered(|ui| {
        let max_h = (ui.available_height() - 108.0).max(200.0);

        let border_color = if state.is_recording {
            Theme::ACCENT_REC
        } else {
            Theme::BORDER
        };

        // Preview Stage Card
        egui::Frame::new()
            .fill(Theme::BG_PANEL)
            .stroke(Stroke::new(1.0_f32, border_color))
            .corner_radius(10.0)
            .inner_margin(Margin::same(12))
            .show(ui, |ui| {
                if let Some(ref img) = state.preview_frame {
                    let color_img =
                        ColorImage::from_rgba_unmultiplied([img.width, img.height], &img.rgba);
                    let texture = preview_texture.insert(ui.ctx().load_texture(
                        "live_preview_frame",
                        color_img,
                        TextureOptions::LINEAR,
                    ));

                    let aspect = img.width as f32 / img.height as f32;
                    let target_h = (max_h - 48.0).clamp(160.0, 500.0);
                    let target_w = target_h * aspect;

                    ui.allocate_ui_with_layout(
                        Vec2::new(target_w.max(280.0), target_h + 24.0),
                        Layout::top_down(Align::Center),
                        |ui| {
                            if state.is_recording {
                                let elapsed = if let Some(start) = state.recording_start {
                                    let sec = (chrono::Local::now() - start).num_seconds().max(0);
                                    format!("{:02}:{:02}", sec / 60, sec % 60)
                                } else {
                                    "00:00".to_string()
                                };
                                ui.label(
                                    RichText::new(format!("●  REC [{elapsed}] · RECORDING"))
                                        .family(Theme::semibold_family())
                                        .size(12.0)
                                        .color(Theme::ACCENT_REC),
                                );
                            } else {
                                ui.label(
                                    RichText::new("●  LIVE PREVIEW")
                                        .family(Theme::semibold_family())
                                        .size(11.5)
                                        .color(Theme::SUCCESS),
                                );
                            }
                            ui.add_space(4.0);
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
                                RichText::new("Live Preview is Off")
                                    .family(Theme::semibold_family())
                                    .size(14.5)
                                    .color(Theme::TEXT_PRIMARY),
                            );
                            ui.add_space(6.0);
                            ui.label(
                                RichText::new("Start Live Preview or press Record below to stream")
                                    .size(12.5)
                                    .color(Theme::TEXT_SECONDARY),
                            );
                        },
                    );
                }
            });

        ui.add_space(12.0);

        // Centered Action Button Deck (444px total width: 186 + 12 + 246)
        ui.allocate_ui_with_layout(
            Vec2::new(444.0, 38.0),
            Layout::left_to_right(Align::Center),
            |ui| {
                ui.spacing_mut().item_spacing.x = 12.0;

                let preview_btn_text = if state.live_preview_active {
                    "⏹  Stop Live Preview"
                } else {
                    "👁  Start Live Preview"
                };

                let preview_btn = egui::Button::new(
                    RichText::new(preview_btn_text)
                        .family(Theme::semibold_family())
                        .size(13.0)
                        .color(Theme::TEXT_PRIMARY),
                )
                .fill(Theme::BG_CARD)
                .stroke(Stroke::new(1.0_f32, Theme::BORDER))
                .min_size(Vec2::new(186.0, 38.0))
                .corner_radius(8.0);

                if ui
                    .add_enabled(state.selected_device_id.is_some(), preview_btn)
                    .clicked()
                {
                    let _ = tx.send(AppMessage::ToggleLivePreview);
                }

                let (rec_text, rec_color) = if state.is_recording {
                    ("⏹  Stop & Save MP4", Theme::ACCENT_REC)
                } else {
                    ("●  Start Recording (REC)", Theme::ACCENT)
                };

                let rec_btn = egui::Button::new(
                    RichText::new(rec_text)
                        .family(Theme::semibold_family())
                        .size(13.5)
                        .color(Color32::WHITE),
                )
                .fill(rec_color)
                .stroke(Stroke::NONE)
                .min_size(Vec2::new(246.0, 38.0))
                .corner_radius(8.0);

                if ui
                    .add_enabled(state.selected_device_id.is_some(), rec_btn)
                    .clicked()
                {
                    let _ = tx.send(AppMessage::ToggleRecording);
                }
            },
        );

        ui.add_space(8.0);

        // Centered Quality & Output Pill Bar (matching 444px width)
        ui.allocate_ui_with_layout(
            Vec2::new(444.0, 34.0),
            Layout::top_down(Align::Center),
            |ui| {
                egui::Frame::new()
                    .fill(Theme::BG_PANEL)
                    .stroke(Stroke::new(1.0_f32, Theme::BORDER))
                    .corner_radius(8.0)
                    .inner_margin(Margin::symmetric(16, 5))
                    .show(ui, |ui| {
                        ui.set_min_width(410.0);
                        ui.horizontal(|ui| {
                            ui.label(
                                RichText::new("Video Bitrate:")
                                    .size(12.0)
                                    .color(Theme::TEXT_SECONDARY),
                            );
                            egui::ComboBox::from_id_salt("bitrate_select")
                                .selected_text(
                                    RichText::new(format!("{} Mbps", state.recording_bitrate_mbps))
                                        .size(12.0)
                                        .family(Theme::semibold_family()),
                                )
                                .width(115.0)
                                .show_ui(ui, |ui| {
                                    ui.selectable_value(
                                        &mut state.recording_bitrate_mbps,
                                        6,
                                        "6 Mbps (Low)",
                                    );
                                    ui.selectable_value(
                                        &mut state.recording_bitrate_mbps,
                                        12,
                                        "12 Mbps (Standard)",
                                    );
                                    ui.selectable_value(
                                        &mut state.recording_bitrate_mbps,
                                        16,
                                        "16 Mbps (High)",
                                    );
                                    ui.selectable_value(
                                        &mut state.recording_bitrate_mbps,
                                        24,
                                        "24 Mbps (Ultra)",
                                    );
                                });

                            ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                                if let Some(ref path) = state.last_recorded_file {
                                    let name = path
                                        .file_name()
                                        .and_then(|n| n.to_str())
                                        .unwrap_or("video.mp4");
                                    ui.label(
                                        RichText::new(format!("✓ {name}"))
                                            .size(11.5)
                                            .color(Theme::SUCCESS),
                                    );
                                } else {
                                    let (dot_rect, _) =
                                        ui.allocate_exact_size(Vec2::new(6.0, 6.0), Sense::hover());
                                    ui.painter().circle_filled(
                                        dot_rect.center(),
                                        2.5,
                                        Theme::TEXT_SECONDARY,
                                    );
                                    ui.label(
                                        RichText::new("MP4 · H.264")
                                            .size(11.5)
                                            .color(Theme::TEXT_SECONDARY),
                                    );
                                }
                            });
                        });
                    });
            },
        );
    });
}
