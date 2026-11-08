pub mod components;
pub mod theme;
pub mod views;

use crate::app::{AppController, AppMessage, AppState};
use crate::domain::AppTab;
use eframe::egui::{self, Key, TextureHandle};
use std::time::Duration;

pub struct AdbStudioApp {
    pub state: AppState,
    pub controller: AppController,
    screenshot_texture: Option<TextureHandle>,
    preview_texture: Option<TextureHandle>,
}

impl AdbStudioApp {
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        theme::Theme::apply_visuals(&cc.egui_ctx);
        let mut state = AppState::default();
        let mut controller = AppController::new();
        controller.init(&mut state);

        Self {
            state,
            controller,
            screenshot_texture: None,
            preview_texture: None,
        }
    }
}

impl eframe::App for AdbStudioApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        // Enforce dark theme consistently regardless of OS system mode
        if !ctx.style().visuals.dark_mode {
            theme::Theme::apply_visuals(ctx);
        }

        // Poll incoming background channel events
        self.controller.poll_updates(&mut self.state);

        // Keyboard shortcut: Space for screenshot
        if self.state.active_tab == AppTab::Screenshot && ctx.input(|i| i.key_pressed(Key::Space)) {
            let _ = self.controller.msg_tx.send(AppMessage::TakeScreenshot);
        }

        // Top bar
        egui::TopBottomPanel::top("top_panel").show(ctx, |ui| {
            components::render_topbar(ui, &mut self.state, &self.controller.msg_tx);
        });

        // Footer
        egui::TopBottomPanel::bottom("bottom_panel").show(ctx, |ui| {
            components::render_footer(ui, &self.state);
        });

        // Central content panel
        egui::CentralPanel::default().show(ctx, |ui| match self.state.active_tab {
            AppTab::Screenshot => {
                views::render_screenshot_view(
                    ui,
                    &mut self.state,
                    &mut self.screenshot_texture,
                    &self.controller.msg_tx,
                );
            }
            AppTab::Recording => {
                views::render_recorder_view(
                    ui,
                    &mut self.state,
                    &mut self.preview_texture,
                    &self.controller.msg_tx,
                );
            }
            AppTab::Logcat => {
                views::render_logcat_view(ui, &mut self.state, &self.controller.msg_tx);
            }
        });

        // Request continuous repaint if live preview or recording or logcat is streaming
        if self.state.live_preview_active
            || self.state.is_recording
            || (self.state.active_tab == AppTab::Logcat && !self.state.logcat_paused)
        {
            ctx.request_repaint_after(Duration::from_millis(30));
        }
    }
}
