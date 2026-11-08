# ADB Studio for macOS 🚀

A lightweight, native macOS companion app for Android developers, QA engineers, and creators. Built with SwiftUI.

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)
![License MIT](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

- 📸 **Fast Screenshot & Auto-Clipboard**: Capture the connected Android device screen with one tap (or Spacebar). Automatically copied to your macOS clipboard with optional Desktop saving.
- 🎥 **Built-in Screen Recording**: Record full HD device video directly via ADB `screenrecord` into `.mp4` format.
- 📜 **Android Studio-Grade Logcat Viewer (Dark Theme)**:
  - Real-time streaming log buffer.
  - Log Level Filtering: **Verbose**, **Debug**, **Info**, **Warn**, **Error**, **Assert**.
  - Package / Process ID (PID) filtering.
  - Tag filtering and Case-Insensitive / Regex search.
  - Auto-scroll & quick log copy.
- 📱 **Multi-Device Support**: Seamlessly detect USB devices, emulators (Cuttlefish, AVD), and Wi-Fi ADB targets (`IP:Port`).
- ⚡ **Native Performance**: 100% native SwiftUI with zero Electron bloat.

---

## 🛠️ Requirements

- macOS 13.0 (Ventura) or newer.
- Android SDK Platform-Tools (`adb`) installed (via Homebrew `brew install android-platform-tools` or Android Studio).

---

## 🚀 Quick Install & Build

Clone this repository and run the build script:

```bash
git clone https://github.com/duinch-tools/adb-studio.git
cd adb-studio
chmod +x build.sh
./build.sh
```

This compiles the binary and automatically installs `/Applications/ADB Studio.app` and CLI command `adb-studio`.

To launch directly:
```bash
open -a "ADB Studio"
# or
adb-studio
```

---

## ⌨️ Shortcuts & CLI

- `Space`: Instant Screenshot
- `adb-studio`: Launch GUI from terminal
- `adb-screenshot`: CLI alias

---

## 📄 License

MIT License. Designed & developed with pair-programming assistance by Antigravity.
