pub mod adapters;
pub mod app;
pub mod domain;
pub mod ui;

use eframe::egui::Vec2;
use ui::AdbStudioApp;

fn main() -> eframe::Result<()> {
    // Initialize tokio multi-thread runtime in background
    let _rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("Failed to initialize tokio runtime");

    let options = eframe::NativeOptions {
        viewport: eframe::egui::ViewportBuilder::default()
            .with_inner_size(Vec2::new(780.0, 680.0))
            .with_min_inner_size(Vec2::new(560.0, 480.0))
            .with_title("ADB Studio — Android Companion"),
        ..Default::default()
    };

    eframe::run_native(
        "ADB Studio",
        options,
        Box::new(|cc| Ok(Box::new(AdbStudioApp::new(cc)))),
    )
}
