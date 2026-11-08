use crate::app::{AppMessage, AppState};
use crate::domain::LogLevel;
use crate::ui::theme::Theme;
use eframe::egui::{self, Color32, Layout, RichText, ScrollArea, TextStyle, Ui};

pub fn render_logcat_view(
    ui: &mut Ui,
    state: &mut AppState,
    tx: &crossbeam_channel::Sender<AppMessage>,
) {
    ui.vertical(|ui| {
        // Toolbar
        egui::Frame::new()
            .fill(Theme::BG_PANEL)
            .inner_margin(egui::Margin::symmetric(10, 6))
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    // Log level combo
                    ui.label(
                        RichText::new("Mức độ:")
                            .size(12.0)
                            .color(Theme::TEXT_SECONDARY),
                    );
                    egui::ComboBox::from_id_salt("log_level_filter")
                        .selected_text(
                            RichText::new(state.logcat_min_level.as_str())
                                .color(Theme::log_level_color(state.logcat_min_level)),
                        )
                        .width(90.0)
                        .show_ui(ui, |ui| {
                            for lvl in LogLevel::ALL {
                                ui.selectable_value(&mut state.logcat_min_level, lvl, lvl.as_str());
                            }
                        });

                    ui.add_space(8.0);

                    // Search box
                    ui.label(RichText::new("🔍").size(12.0));
                    ui.add(
                        egui::TextEdit::singleline(&mut state.logcat_search)
                            .hint_text("Tìm kiếm log...")
                            .desired_width(180.0),
                    );

                    ui.add_space(8.0);

                    // Package filter
                    ui.label(RichText::new("📦").size(12.0));
                    ui.add(
                        egui::TextEdit::singleline(&mut state.logcat_package)
                            .hint_text("Package / PID...")
                            .desired_width(130.0),
                    );

                    ui.with_layout(Layout::right_to_left(egui::Align::Center), |ui| {
                        // Copy button
                        if ui.button(RichText::new("📋 Copy").size(12.0)).clicked() {
                            let _ = tx.send(AppMessage::CopyLogcat);
                        }

                        // Clear button
                        if ui.button(RichText::new("🗑 Clear").size(12.0)).clicked() {
                            let _ = tx.send(AppMessage::ClearLogcat);
                        }

                        // Pause button
                        let pause_label = if state.logcat_paused {
                            "▶ Tiếp tục"
                        } else {
                            "⏸ Tạm dừng"
                        };
                        if ui.button(RichText::new(pause_label).size(12.0)).clicked() {
                            let _ = tx.send(AppMessage::ToggleLogcatPause);
                        }

                        // Auto-scroll checkbox
                        ui.checkbox(&mut state.logcat_auto_scroll, "Tự cuộn");
                    });
                });
            });

        ui.add_space(2.0);

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

        // Log table header
        ui.horizontal(|ui| {
            ui.label(
                RichText::new(format!(
                    "Hiển thị: {} / {} logs",
                    filtered_logs.len(),
                    state.logs.len()
                ))
                .size(11.0)
                .color(Theme::TEXT_SECONDARY),
            );
        });

        // Virtualized Scroll Area
        let scroll = ScrollArea::vertical()
            .auto_shrink([false, false])
            .stick_to_bottom(state.logcat_auto_scroll);

        scroll.show_rows(
            ui,
            ui.text_style_height(&TextStyle::Monospace) + 4.0,
            filtered_logs.len(),
            |ui, row_range| {
                for i in row_range {
                    let log = filtered_logs[i];
                    let lvl_color = Theme::log_level_color(log.level);

                    ui.horizontal(|ui| {
                        // Timestamp
                        ui.label(
                            RichText::new(&log.timestamp)
                                .monospace()
                                .size(11.0)
                                .color(Color32::from_rgb(130, 134, 145)),
                        );
                        // PID/TID
                        ui.label(
                            RichText::new(format!("{}/{}", log.pid, log.tid))
                                .monospace()
                                .size(11.0)
                                .color(Color32::from_rgb(110, 115, 125)),
                        );
                        // Level Tag Badge
                        ui.label(
                            RichText::new(log.level.short_tag())
                                .monospace()
                                .size(11.0)
                                .strong()
                                .color(lvl_color),
                        );
                        // Tag
                        ui.label(
                            RichText::new(format!("{}:", log.tag))
                                .monospace()
                                .size(11.0)
                                .color(Color32::from_rgb(88, 166, 255)),
                        );
                        // Message
                        ui.label(
                            RichText::new(&log.message)
                                .monospace()
                                .size(11.0)
                                .color(lvl_color),
                        );
                    });
                }
            },
        );
    });
}
