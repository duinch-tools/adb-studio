use crate::app::{AppMessage, AppState};
use crate::domain::AppTab;
use crate::ui::theme::Theme;
use eframe::egui::{self, Color32, Layout, Margin, RichText, Sense, Stroke, Ui, Vec2};

pub fn render_topbar(
    ui: &mut Ui,
    state: &mut AppState,
    tx: &crossbeam_channel::Sender<AppMessage>,
) {
    ui.horizontal(|ui| {
        ui.spacing_mut().item_spacing.x = 10.0;

        // App Brand Title
        ui.label(
            RichText::new("⚡ ADB Studio")
                .family(Theme::semibold_family())
                .size(15.0)
                .color(Theme::TEXT_PRIMARY),
        );

        ui.add_space(4.0);
        ui.separator();
        ui.add_space(4.0);

        // Painted Status Indicator Dot (replaces missing-glyph emoji)
        let has_device = state.selected_device_id.is_some();
        let dot_color = if has_device {
            Theme::SUCCESS
        } else {
            Theme::ACCENT_REC
        };
        let (dot_rect, _) = ui.allocate_exact_size(Vec2::new(10.0, 10.0), Sense::hover());
        ui.painter()
            .circle_filled(dot_rect.center(), 4.5, dot_color);

        let selected_label = if let Some(ref id) = state.selected_device_id {
            state
                .devices
                .iter()
                .find(|d| &d.id == id)
                .map(|d| d.display_name())
                .unwrap_or_else(|| id.clone())
        } else {
            "No device connected".to_string()
        };

        egui::ComboBox::from_id_salt("device_selector")
            .selected_text(
                RichText::new(selected_label)
                    .size(12.5)
                    .color(Theme::TEXT_PRIMARY),
            )
            .width(225.0)
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

        let refresh_btn = egui::Button::new(
            RichText::new("↻")
                .size(14.0)
                .family(Theme::semibold_family())
                .color(Theme::TEXT_PRIMARY),
        )
        .min_size(Vec2::new(30.0, 28.0))
        .corner_radius(6.0);

        if ui
            .add(refresh_btn)
            .on_hover_text("Refresh ADB devices")
            .clicked()
        {
            let _ = tx.send(AppMessage::RefreshDevices);
        }

        // Right-aligned Segmented Pill Tab Switcher
        ui.with_layout(Layout::right_to_left(egui::Align::Center), |ui| {
            egui::Frame::new()
                .fill(Theme::BG_VOID)
                .stroke(Stroke::new(1.0_f32, Theme::BORDER))
                .corner_radius(8.0)
                .inner_margin(Margin::symmetric(3, 3))
                .show(ui, |ui| {
                    ui.spacing_mut().item_spacing.x = 4.0;
                    for tab in AppTab::ALL.iter().rev() {
                        let is_active = state.active_tab == *tab;
                        let text = format!("{}  {}", tab.icon(), tab.short_name());

                        let (fill, text_color) = if is_active {
                            (Theme::ACCENT, Color32::WHITE)
                        } else {
                            (Color32::TRANSPARENT, Theme::TEXT_SECONDARY)
                        };

                        let btn = egui::Button::new(
                            RichText::new(text)
                                .family(Theme::semibold_family())
                                .size(12.5)
                                .color(text_color),
                        )
                        .fill(fill)
                        .stroke(Stroke::NONE)
                        .min_size(Vec2::new(100.0, 26.0))
                        .corner_radius(6.0);

                        if ui.add(btn).clicked() {
                            let _ = tx.send(AppMessage::SwitchTab(*tab));
                        }
                    }
                });
        });
    });
}
