use crate::app::{AppMessage, AppState};
use crate::domain::AppTab;
use crate::ui::theme::Theme;
use eframe::egui::{self, Color32, Layout, RichText, Ui};

pub fn render_topbar(
    ui: &mut Ui,
    state: &mut AppState,
    tx: &crossbeam_channel::Sender<AppMessage>,
) {
    egui::Frame::new()
        .fill(Theme::BG_PANEL)
        .inner_margin(egui::Margin::symmetric(14, 10))
        .show(ui, |ui| {
            ui.horizontal(|ui| {
                // Title
                ui.label(
                    RichText::new("⚡ ADB Studio")
                        .strong()
                        .size(15.0)
                        .color(Theme::TEXT_PRIMARY),
                );
                ui.add_space(16.0);

                // Device selector
                let has_device = state.selected_device_id.is_some();
                let status_dot = if has_device { "🟢" } else { "🔴" };
                ui.label(RichText::new(status_dot).size(11.0));

                let selected_label = if let Some(ref id) = state.selected_device_id {
                    state
                        .devices
                        .iter()
                        .find(|d| &d.id == id)
                        .map(|d| d.display_name())
                        .unwrap_or_else(|| id.clone())
                } else {
                    "Chưa kết nối thiết bị".to_string()
                };

                egui::ComboBox::from_id_salt("device_selector")
                    .selected_text(RichText::new(selected_label).size(13.0))
                    .width(220.0)
                    .show_ui(ui, |ui| {
                        for dev in &state.devices {
                            let is_selected = state.selected_device_id.as_deref() == Some(&dev.id);
                            if ui
                                .selectable_label(is_selected, dev.display_name())
                                .clicked()
                            {
                                let _ = tx.send(AppMessage::SelectDevice(dev.id.clone()));
                            }
                        }
                    });

                if ui
                    .button(RichText::new("🔄").size(12.0))
                    .on_hover_text("Tìm lại thiết bị ADB")
                    .clicked()
                {
                    let _ = tx.send(AppMessage::RefreshDevices);
                }

                ui.with_layout(Layout::right_to_left(egui::Align::Center), |ui| {
                    for tab in AppTab::ALL.iter().rev() {
                        let is_active = state.active_tab == *tab;
                        let text = format!("{} {}", tab.icon(), tab.short_name());
                        let btn = if is_active {
                            ui.button(RichText::new(text).color(Color32::WHITE).strong())
                        } else {
                            ui.button(RichText::new(text).color(Theme::TEXT_SECONDARY))
                        };

                        if btn.clicked() {
                            let _ = tx.send(AppMessage::SwitchTab(*tab));
                        }
                    }
                });
            });
        });
}
