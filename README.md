# ADB Studio 🚀

A high-performance, cross-platform Android companion desktop app built in **Rust** with **`egui`** and **`tokio`**.

![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Windows%20%7C%20Linux-blue?logo=rust)
![Rust 2024](https://img.shields.io/badge/Rust-2024%20Edition-orange?logo=rust)
![License MIT](https://img.shields.io/badge/License-MIT-green)
![CI](https://github.com/duinch-tools/adb-studio/actions/workflows/rust.yml/badge.svg)

---

## ✨ Features

- 📸 **Fast Screenshot & Auto-Clipboard**: Capture the Android device screen with one tap or keyboard shortcut (`Space`). Automatically copies raw RGBA image to your OS clipboard (macOS, Windows, Linux) and optional Desktop saving.
- 🎥 **Live Preview Screen Recording**:
  - **Live Screen Mirroring**: Watch your device screen live at 30–60 FPS directly on your desktop canvas while recording or in idle mode.
  - **Hardware MP4 Recording**: High-bitrate recording (6–24 Mbps) directly via Android hardware encoder (`screenrecord`) with clean MP4 finalization and auto-save.
- 📜 **Android Studio Logcat Viewer (Dark Theme)**:
  - Real-time streaming log buffer powered by non-blocking `tokio::process`.
  - Color-coded Log Levels: **Verbose** (gray), **Debug** (blue), **Info** (green), **Warn** (amber), **Error** (red), **Assert** (purple).
  - Instant Tag, Package Name, and Process ID (PID) filtering.
  - Case-insensitive search query filter.
  - Pause/Resume, Clear, and 1-click clipboard export.
  - Virtualized scroll list supporting thousands of log lines with zero frame drops.
- 📱 **Multi-Device Support**: Auto-detects USB devices, Emulators (Cuttlefish, AVD), and Wi-Fi ADB connections (`IP:Port`).
- ⚡ **Ultra-Lightweight & Fast**: Pure Rust native GUI, < 15MB binary size, starts up in < 50ms, and consumes under 25MB RAM.

---

## 🛠️ Requirements

- Android SDK Platform-Tools (`adb`) installed and accessible in `PATH`.
  - **macOS**: `brew install android-platform-tools`
  - **Linux**: `sudo apt install adb` or distro package manager
  - **Windows**: `winget install Google.PlatformTools` or extract to PATH

---

## 🚀 Quick Install & Run

### Download Pre-built Binaries
Grab the latest release for your platform from [Releases](https://github.com/duinch-tools/adb-studio/releases):
- **macOS**: `adb-studio-macos-arm64.tar.gz` / `adb-studio-macos-x64.tar.gz`
- **Linux**: `adb-studio-linux-x86_64.tar.gz`
- **Windows**: `adb-studio-windows-x64.zip`

### Build from Source
```bash
git clone https://github.com/duinch-tools/adb-studio.git
cd adb-studio

# Run dev
cargo run --release

# Run tests
cargo test
```

---

## ⌨️ Shortcuts

- `Space`: Instant Screenshot (when on Screenshot tab)
- `Enter` / Click: Start / Stop recording

---

## 📄 License

MIT License. Developed with pair-programming assistance by Antigravity for [duinch-tools](https://github.com/duinch-tools).
