pub mod adapters;
pub mod app;
pub mod domain;
pub mod ui;

use eframe::egui::Vec2;
use std::sync::Arc;
use ui::AdbStudioApp;

fn load_app_icon() -> Option<Arc<eframe::egui::IconData>> {
    let png_bytes = include_bytes!("../Resources/AppIcon.png");
    let img = image::load_from_memory(png_bytes).ok()?;
    let rgba = img.to_rgba8();
    let (width, height) = rgba.dimensions();
    Some(Arc::new(eframe::egui::IconData {
        rgba: rgba.into_raw(),
        width,
        height,
    }))
}

fn main() -> eframe::Result<()> {
    // Initialize tokio multi-thread runtime in background
    let _rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("Failed to initialize tokio runtime");

    let mut viewport = eframe::egui::ViewportBuilder::default()
        .with_inner_size(Vec2::new(780.0, 680.0))
        .with_min_inner_size(Vec2::new(560.0, 480.0))
        .with_title("ADB Studio — Android Companion");

    if let Some(icon) = load_app_icon() {
        viewport = viewport.with_icon(icon);
    }

    let options = eframe::NativeOptions {
        viewport,
        ..Default::default()
    };

    eframe::run_native(
        "ADB Studio",
        options,
        Box::new(|cc| Ok(Box::new(AdbStudioApp::new(cc)))),
    )
}
