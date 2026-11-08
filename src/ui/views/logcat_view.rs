use crate::app::{AppMessage, AppState};
use crate::domain::LogLevel;
use crate::ui::theme::Theme;
use eframe::egui::{
    self, Align, Color32, Layout, Margin, RichText, ScrollArea, Stroke, TextStyle, Ui, Vec2,
};

pub fn render_logcat_view(
    ui: &mut Ui,
    state: &mut AppState,
    tx: &crossbeam_channel::Sender<AppMessage>,
) {
    ui.vertical(|ui| {
        // Toolbar Card
        egui::Frame::new()
            .fill(Theme::BG_PANEL)
            .stroke(Stroke::new(1.0_f32, Theme::BORDER))
            .corner_radius(8.0)
            .inner_margin(Margin::symmetric(12, 8))
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.spacing_mut().item_spacing.x = 8.0;

                    // Log level combo
                    ui.label(
                        RichText::new("Level:")
                            .size(12.0)
                            .color(Theme::TEXT_SECONDARY),
                    );
                    egui::ComboBox::from_id_salt("log_level_filter")
                        .selected_text(
                            RichText::new(state.logcat_min_level.as_str())
                                .family(Theme::semibold_family())
                                .size(12.0)
                                .color(Theme::log_level_color(state.logcat_min_level)),
                        )
                        .width(88.0)
                        .show_ui(ui, |ui| {
                            for lvl in LogLevel::ALL {
                                ui.selectable_value(&mut state.logcat_min_level, lvl, lvl.as_str());
                            }
                        });

                    ui.add_space(4.0);

                    // Search box
                    ui.add(
                        egui::TextEdit::singleline(&mut state.logcat_search)
                            .hint_text("🔍  Search logs...")
                            .desired_width(165.0),
                    );

                    // Package filter
                    ui.add(
                        egui::TextEdit::singleline(&mut state.logcat_package)
                            .hint_text("📦  Package / PID...")
                            .desired_width(125.0),
                    );

                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                        ui.spacing_mut().item_spacing.x = 6.0;

                        let copy_btn = egui::Button::new(
                            RichText::new("📋  Copy")
                                .family(Theme::semibold_family())
                                .size(12.0),
                        )
                        .min_size(Vec2::new(68.0, 26.0))
                        .corner_radius(6.0);
                        if ui.add(copy_btn).clicked() {
                            let _ = tx.send(AppMessage::CopyLogcat);
                        }

                        let clear_btn = egui::Button::new(
                            RichText::new("🗑  Clear")
                                .family(Theme::semibold_family())
                                .size(12.0),
                        )
                        .min_size(Vec2::new(68.0, 26.0))
                        .corner_radius(6.0);
                        if ui.add(clear_btn).clicked() {
                            let _ = tx.send(AppMessage::ClearLogcat);
                        }

                        let pause_label = if state.logcat_paused {
                            "▶  Resume"
                        } else {
                            "⏸  Pause"
                        };
                        let pause_btn = egui::Button::new(
                            RichText::new(pause_label)
                                .family(Theme::semibold_family())
                                .size(12.0),
                        )
                        .min_size(Vec2::new(78.0, 26.0))
                        .corner_radius(6.0);
                        if ui.add(pause_btn).clicked() {
                            let _ = tx.send(AppMessage::ToggleLogcatPause);
                        }

                        ui.add_space(4.0);
                        ui.checkbox(&mut state.logcat_auto_scroll, "Auto-scroll");
                    });
                });
            });

        ui.add_space(6.0);

        // Filter logs
        let query = state.logcat_search.to_lowercase();
        let pkg_query = state.logcat_package.to_lowercase();
        let min_level = state.logcat_min_level;

        let filtered_logs: Vec<_> = state
            .logs
            .iter()
            .filter(|log| {
                if log.level < min_level {
                    return false;
                }
                if !query.is_empty()
                    && !log.message.to_lowercase().contains(&query)
                    && !log.tag.to_lowercase().contains(&query)
                {
                    return false;
                }
                if !pkg_query.is_empty()
                    && !log.pid.contains(&pkg_query)
                    && !log.tag.to_lowercase().contains(&pkg_query)
                {
                    return false;
                }
                true
            })
            .collect();

        // Log stream container
        egui::Frame::new()
            .fill(Theme::BG_PANEL)
            .stroke(Stroke::new(1.0_f32, Theme::BORDER))
            .corner_radius(8.0)
            .inner_margin(Margin::symmetric(12, 8))
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.label(
                        RichText::new(format!(
                            "Showing {} of {} entries",
                            filtered_logs.len(),
                            state.logs.len()
                        ))
                        .size(11.0)
                        .color(Theme::TEXT_SECONDARY),
                    );
                });
                ui.separator();

                let scroll = ScrollArea::vertical()
                    .auto_shrink([false, false])
                    .stick_to_bottom(state.logcat_auto_scroll);

                scroll.show_rows(
                    ui,
                    ui.text_style_height(&TextStyle::Monospace) + 5.0,
                    filtered_logs.len(),
                    |ui, row_range| {
                        for i in row_range {
                            let log = filtered_logs[i];
                            let lvl_color = Theme::log_level_color(log.level);

                            ui.horizontal(|ui| {
                                ui.spacing_mut().item_spacing.x = 8.0;
                                // Timestamp
                                ui.label(
                                    RichText::new(&log.timestamp)
                                        .monospace()
                                        .size(11.5)
                                        .color(Color32::from_rgb(130, 136, 148)),
                                );
                                // PID/TID
                                ui.label(
                                    RichText::new(format!("{}/{}", log.pid, log.tid))
                                        .monospace()
                                        .size(11.5)
                                        .color(Color32::from_rgb(108, 114, 128)),
                                );
                                // Level Tag Badge
                                ui.label(
                                    RichText::new(log.level.short_tag())
                                        .monospace()
                                        .size(11.5)
                                        .color(lvl_color),
                                );
                                // Tag
                                ui.label(
                                    RichText::new(format!("{}:", log.tag))
                                        .monospace()
                                        .size(11.5)
                                        .color(Color32::from_rgb(96, 165, 250)),
                                );
                                // Message
                                ui.label(
                                    RichText::new(&log.message)
                                        .monospace()
                                        .size(11.5)
                                        .color(lvl_color),
                                );
                            });
                        }
                    },
                );
            });
    });
}
