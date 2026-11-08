import SwiftUI
import AppKit

// MARK: - State Management

class AppState: ObservableObject {
    @Published var activeTab: AppTab = .screenshot
    
    // Devices
    @Published var devices: [AdbDevice] = []
    @Published var selectedDeviceId: String = ""
    @Published var statusMessage: String = "Sẵn sàng"
    @Published var isError: Bool = false
    
    // Screenshot State
    @Published var isCapturing: Bool = false
    @Published var lastImage: NSImage? = nil
    @Published var lastSavedURL: URL? = nil
    @Published var showCopiedAlert: Bool = false
    
    // Screen Recording State
    @Published var isRecording: Bool = false
    @Published var recordingDuration: Int = 0
    @Published var lastRecordedURL: URL? = nil
    @Published var isProcessingRecord: Bool = false
    @Published var recordingQuality: String = "12M"
    
    // Logcat State
    @Published var logs: [LogEntry] = []
    @Published var logcatLevel: LogLevel = .verbose
    @Published var logcatSearchQuery: String = ""
    @Published var logcatSelectedPackage: String = "All"
    @Published var runningPackages: [String] = []
    @Published var isLogcatPaused: Bool = false
    @Published var autoScrollLogcat: Bool = true
    
    // Preferences
    @AppStorage("copyToClipboard") var copyToClipboard: Bool = true
    @AppStorage("saveToDesktop") var saveToDesktop: Bool = true
    @AppStorage("autoCaptureOnLaunch") var autoCaptureOnLaunch: Bool = true
    @AppStorage("lastUsedDeviceId") var lastUsedDeviceId: String = ""
    
    var recordTimer: Timer?
    var logcatProcess: Process?
    var logcatPipe: Pipe?
    var pidPackageMap: [String: String] = [:]
    var logBuffer: [LogEntry] = []
    var logUpdateTimer: Timer?
    let maxLogCount = 2500
    
    let shutterSoundURL = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif")
    
    init() {
        refreshDevices { [weak self] in
            guard let self = self else { return }
            if self.autoCaptureOnLaunch && !self.selectedDeviceId.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.capture()
                }
            }
        }
    }
    
    deinit {
        stopLogcat()
        recordTimer?.invalidate()
        logUpdateTimer?.invalidate()
    }
    

}
