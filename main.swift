import SwiftUI
import AppKit

// MARK: - Models

struct AdbDevice: Identifiable, Hashable {
    let id: String
    let model: String
    
    var displayName: String {
        return "\(model) (\(id))"
    }
}

enum LogLevel: String, CaseIterable, Identifiable {
    case verbose = "Verbose"
    case debug = "Debug"
    case info = "Info"
    case warn = "Warn"
    case error = "Error"
    case assert = "Assert"
    
    var id: String { rawValue }
    
    var shortTag: String {
        switch self {
        case .verbose: return "V"
        case .debug: return "D"
        case .info: return "I"
        case .warn: return "W"
        case .error: return "E"
        case .assert: return "A"
        }
    }
    
    var priority: Int {
        switch self {
        case .verbose: return 2
        case .debug: return 3
        case .info: return 4
        case .warn: return 5
        case .error: return 6
        case .assert: return 7
        }
    }
    
    var color: Color {
        switch self {
        case .verbose: return Color(red: 0.65, green: 0.67, blue: 0.72) // Gray
        case .debug: return Color(red: 0.35, green: 0.65, blue: 0.96)   // Soft Blue
        case .info: return Color(red: 0.35, green: 0.78, blue: 0.52)    // Mint Green
        case .warn: return Color(red: 0.96, green: 0.72, blue: 0.24)    // Amber Orange
        case .error: return Color(red: 0.98, green: 0.35, blue: 0.35)   // Coral Red
        case .assert: return Color(red: 0.75, green: 0.45, blue: 0.95)  // Purple
        }
    }
    
    static func from(tag: String) -> LogLevel {
        switch tag.uppercased() {
        case "V": return .verbose
        case "D": return .debug
        case "I": return .info
        case "W": return .warn
        case "E": return .error
        case "F", "A": return .assert
        default: return .verbose
        }
    }
}

struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let time: String
    let pid: String
    let tid: String
    let level: LogLevel
    let tag: String
    let message: String
}

enum AppTab: String, CaseIterable {
    case screenshot = "Chụp ảnh"
    case recording = "Quay video"
    case logcat = "Logcat"
    
    var iconName: String {
        switch self {
        case .screenshot: return "camera.fill"
        case .recording: return "record.circle.fill"
        case .logcat: return "terminal.fill"
        }
    }
}

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
    
    private var recordTimer: Timer?
    private var logcatProcess: Process?
    private var logcatPipe: Pipe?
    private var pidPackageMap: [String: String] = [:]
    private var logBuffer: [LogEntry] = []
    private var logUpdateTimer: Timer?
    private let maxLogCount = 2500
    
    private let shutterSoundURL = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif")
    
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
    
    // MARK: - ADB Discovery
    
    func getAdbPath() -> String? {
        let candidatePaths = [
            "/opt/homebrew/bin/adb",
            "/usr/local/bin/adb",
            "\(NSHomeDirectory())/Library/Android/sdk/platform-tools/adb"
        ]
        for path in candidatePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        proc.arguments = ["adb"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let out = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !out.isEmpty, FileManager.default.isExecutableFile(atPath: out) {
            return out
        }
        return nil
    }
    
    func refreshDevices(completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let adb = self.getAdbPath() else {
                DispatchQueue.main.async {
                    self.devices = []
                    self.selectedDeviceId = ""
                    self.statusMessage = "Không tìm thấy ADB trên hệ thống"
                    self.isError = true
                    completion?()
                }
                return
            }
            
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: adb)
            proc.arguments = ["devices"]
            let pipe = Pipe()
            proc.standardOutput = pipe
            try? proc.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            
            var found: [AdbDevice] = []
            if let out = String(data: data, encoding: .utf8) {
                let lines = out.components(separatedBy: .newlines)
                for line in lines.dropFirst() {
                    let parts = line.split(separator: "\t")
                    if parts.count >= 2 && parts[1] == "device" {
                        let serial = String(parts[0])
                        let mProc = Process()
                        mProc.executableURL = URL(fileURLWithPath: adb)
                        mProc.arguments = ["-s", serial, "shell", "getprop", "ro.product.model"]
                        let mPipe = Pipe()
                        mProc.standardOutput = mPipe
                        try? mProc.run()
                        let mData = mPipe.fileHandleForReading.readDataToEndOfFile()
                        mProc.waitUntilExit()
                        let model = String(data: mData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        found.append(AdbDevice(id: serial, model: model.isEmpty ? "Android Device" : model))
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.devices = found
                if found.isEmpty {
                    self.selectedDeviceId = ""
                    self.statusMessage = "Chưa kết nối thiết bị nào"
                    self.isError = true
                } else {
                    self.isError = false
                    if let matched = found.first(where: { $0.id == self.lastUsedDeviceId }) {
                        self.selectedDeviceId = matched.id
                    } else if let first = found.first {
                        self.selectedDeviceId = first.id
                    }
                    self.statusMessage = "\(found.count) thiết bị sẵn sàng"
                    
                    if self.activeTab == .logcat {
                        self.startLogcat()
                    }
                }
                completion?()
            }
        }
    }
    
    // MARK: - Screenshot
    
    func capture() {
        guard !selectedDeviceId.isEmpty else {
            statusMessage = "Vui lòng chọn thiết bị trước"
            isError = true
            return
        }
        guard let adb = getAdbPath() else {
            statusMessage = "Không tìm thấy ADB"
            isError = true
            return
        }
        
        isCapturing = true
        statusMessage = "Đang chụp màn hình..."
        isError = false
        
        let targetId = selectedDeviceId
        lastUsedDeviceId = targetId
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: adb)
            proc.arguments = ["-s", targetId, "exec-out", "screencap", "-p"]
            let pipe = Pipe()
            proc.standardOutput = pipe
            
            var rawData: Data? = nil
            do {
                try proc.run()
                rawData = pipe.fileHandleForReading.readDataToEndOfFile()
                proc.waitUntilExit()
            } catch {
                DispatchQueue.main.async {
                    self.isCapturing = false
                    self.statusMessage = "Lỗi thực thi ADB: \(error.localizedDescription)"
                    self.isError = true
                }
                return
            }
            
            guard let data = rawData, data.count > 100,
                  data.prefix(8) == Data([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]) else {
                // Fallback via sdcard
                let fbProc = Process()
                fbProc.executableURL = URL(fileURLWithPath: adb)
                fbProc.arguments = ["-s", targetId, "shell", "screencap", "-p", "/sdcard/_tmp_cap.png"]
                try? fbProc.run()
                fbProc.waitUntilExit()
                
                let pullProc = Process()
                pullProc.executableURL = URL(fileURLWithPath: adb)
                let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("adb_cap_\(UUID().uuidString).png")
                pullProc.arguments = ["-s", targetId, "pull", "/sdcard/_tmp_cap.png", tmpURL.path]
                try? pullProc.run()
                pullProc.waitUntilExit()
                
                let rmProc = Process()
                rmProc.executableURL = URL(fileURLWithPath: adb)
                rmProc.arguments = ["-s", targetId, "shell", "rm", "-f", "/sdcard/_tmp_cap.png"]
                try? rmProc.run()
                rmProc.waitUntilExit()
                
                guard let fallbackData = try? Data(contentsOf: tmpURL), fallbackData.count > 100 else {
                    DispatchQueue.main.async {
                        self.isCapturing = false
                        self.statusMessage = "Chụp thất bại, kiểm tra thiết bị"
                        self.isError = true
                    }
                    return
                }
                self.processCapturedData(fallbackData, targetId: targetId)
                return
            }
            
            self.processCapturedData(data, targetId: targetId)
        }
    }
    
    private func processCapturedData(_ data: Data, targetId: String) {
        var savedURL: URL? = nil
        
        if saveToDesktop {
            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH.mm.ss"
            let timeStr = formatter.string(from: Date())
            let fileURL = desktop.appendingPathComponent("ADB_Screenshot_\(timeStr).png")
            try? data.write(to: fileURL)
            savedURL = fileURL
        }
        
        let image = NSImage(data: data)
        
        if copyToClipboard {
            let p = NSPasteboard.general
            p.clearContents()
            p.setData(data, forType: .png)
            if let img = image, let tiff = img.tiffRepresentation {
                p.setData(tiff, forType: .tiff)
            }
        }
        
        if FileManager.default.fileExists(atPath: shutterSoundURL.path) {
            NSSound(contentsOf: shutterSoundURL, byReference: true)?.play()
        } else {
            NSSound.beep()
        }
        
        DispatchQueue.main.async {
            self.isCapturing = false
            self.lastImage = image
            self.lastSavedURL = savedURL
            self.statusMessage = "Đã chụp & sao chép vào Clipboard!"
            self.isError = false
            self.showCopiedAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.showCopiedAlert = false
            }
        }
    }
    
    func copyCurrentImageToClipboard() {
        guard let img = lastImage, let tiff = img.tiffRepresentation else { return }
        let p = NSPasteboard.general
        p.clearContents()
        p.setData(tiff, forType: .tiff)
        if let rep = NSBitmapImageRep(data: tiff), let pngData = rep.representation(using: .png, properties: [:]) {
            p.setData(pngData, forType: .png)
        }
        showCopiedAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showCopiedAlert = false
        }
    }
    
    func openLastFileInFinder() {
        guard let url = lastSavedURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    // MARK: - Screen Recording
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard !selectedDeviceId.isEmpty else {
            statusMessage = "Chưa chọn thiết bị"
            isError = true
            return
        }
        guard let adb = getAdbPath() else { return }
        
        isRecording = true
        recordingDuration = 0
        statusMessage = "Đang quay màn hình..."
        isError = false
        
        let targetId = selectedDeviceId
        
        // Start duration timer
        recordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 1
            if self.recordingDuration >= 180 { // Android screenrecord limit is 180s
                self.stopRecording()
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: adb)
            proc.arguments = ["-s", targetId, "shell", "screenrecord", "--bit-rate", "12000000", "/sdcard/_adb_record.mp4"]
            try? proc.run()
            proc.waitUntilExit()
        }
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        recordTimer?.invalidate()
        recordTimer = nil
        isRecording = false
        isProcessingRecord = true
        statusMessage = "Đang lưu video..."
        
        let targetId = selectedDeviceId
        guard let adb = getAdbPath() else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Stop screenrecord gracefully on device
            let stopProc = Process()
            stopProc.executableURL = URL(fileURLWithPath: adb)
            stopProc.arguments = ["-s", targetId, "shell", "pkill -2 -f screenrecord || killall -2 screenrecord"]
            try? stopProc.run()
            stopProc.waitUntilExit()
            
            // Wait for MP4 container header to flush
            Thread.sleep(forTimeInterval: 1.5)
            
            // Pull video to Desktop
            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH.mm.ss"
            let timeStr = formatter.string(from: Date())
            let destURL = desktop.appendingPathComponent("ADB_Recording_\(timeStr).mp4")
            
            let pullProc = Process()
            pullProc.executableURL = URL(fileURLWithPath: adb)
            pullProc.arguments = ["-s", targetId, "pull", "/sdcard/_adb_record.mp4", destURL.path]
            try? pullProc.run()
            pullProc.waitUntilExit()
            
            // Cleanup on device
            let rmProc = Process()
            rmProc.executableURL = URL(fileURLWithPath: adb)
            rmProc.arguments = ["-s", targetId, "shell", "rm", "-f", "/sdcard/_adb_record.mp4"]
            try? rmProc.run()
            rmProc.waitUntilExit()
            
            if FileManager.default.fileExists(atPath: destURL.path) {
                // Copy file URL to clipboard
                let p = NSPasteboard.general
                p.clearContents()
                p.writeObjects([destURL as NSURL])
                
                NSSound(contentsOf: self.shutterSoundURL, byReference: true)?.play()
                
                DispatchQueue.main.async {
                    self.isProcessingRecord = false
                    self.lastRecordedURL = destURL
                    self.statusMessage = "Đã lưu video vào Desktop & Clipboard!"
                    self.showCopiedAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.showCopiedAlert = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isProcessingRecord = false
                    self.statusMessage = "Lỗi khi lưu video quay màn hình"
                    self.isError = true
                }
            }
        }
    }
    
    // MARK: - Logcat (Android Studio style)
    
    func startLogcat() {
        stopLogcat()
        guard !selectedDeviceId.isEmpty, let adb = getAdbPath() else { return }
        
        let targetId = selectedDeviceId
        
        // Refresh running processes/packages
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let psProc = Process()
            psProc.executableURL = URL(fileURLWithPath: adb)
            psProc.arguments = ["-s", targetId, "shell", "ps", "-A", "-o", "PID,NAME"]
            let psPipe = Pipe()
            psProc.standardOutput = psPipe
            try? psProc.run()
            let data = psPipe.fileHandleForReading.readDataToEndOfFile()
            psProc.waitUntilExit()
            
            var map: [String: String] = [:]
            var packages: Set<String> = []
            if let out = String(data: data, encoding: .utf8) {
                let lines = out.components(separatedBy: .newlines)
                for line in lines.dropFirst() {
                    let parts = line.trimmingCharacters(in: .whitespaces).split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                    if parts.count >= 2 {
                        let pid = String(parts[0])
                        let name = String(parts[1])
                        map[pid] = name
                        if name.contains(".") && !name.hasPrefix("[") {
                            packages.insert(name)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.pidPackageMap = map
                self.runningPackages = ["All"] + packages.sorted()
            }
        }
        
        // Start logcat process
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: adb)
        proc.arguments = ["-s", targetId, "logcat", "-v", "threadtime"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        
        var bufferString = ""
        let fh = pipe.fileHandleForReading
        fh.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            
            bufferString += text
            var newEntries: [LogEntry] = []
            while let newlineRange = bufferString.range(of: "\n") {
                let line = String(bufferString[..<newlineRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                bufferString.removeSubrange(..<newlineRange.upperBound)
                
                if let entry = self.parseLogLine(line) {
                    newEntries.append(entry)
                }
            }
            
            if !newEntries.isEmpty {
                DispatchQueue.main.async {
                    if !self.isLogcatPaused {
                        self.logBuffer.append(contentsOf: newEntries)
                    }
                }
            }
        }
        
        do {
            try proc.run()
            logcatProcess = proc
            logcatPipe = pipe
        } catch {
            statusMessage = "Lỗi khởi động Logcat: \(error.localizedDescription)"
        }
        
        // Timer to batch flush logBuffer to published logs at 10Hz
        logUpdateTimer?.invalidate()
        logUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, !self.logBuffer.isEmpty else { return }
            var current = self.logs
            current.append(contentsOf: self.logBuffer)
            self.logBuffer.removeAll()
            if current.count > self.maxLogCount {
                current.removeFirst(current.count - self.maxLogCount)
            }
            self.logs = current
        }
    }
    
    func stopLogcat() {
        logUpdateTimer?.invalidate()
        logUpdateTimer = nil
        logcatPipe?.fileHandleForReading.readabilityHandler = nil
        logcatPipe = nil
        if let proc = logcatProcess, proc.isRunning {
            proc.terminate()
        }
        logcatProcess = nil
        logBuffer.removeAll()
    }
    
    func clearLogcat() {
        logs.removeAll()
        logBuffer.removeAll()
        guard !selectedDeviceId.isEmpty, let adb = getAdbPath() else { return }
        let targetId = selectedDeviceId
        DispatchQueue.global(qos: .utility).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: adb)
            proc.arguments = ["-s", targetId, "logcat", "-c"]
            try? proc.run()
            proc.waitUntilExit()
        }
    }
    
    private func parseLogLine(_ line: String) -> LogEntry? {
        guard !line.isEmpty, !line.hasPrefix("---------") else { return nil }
        
        // Pattern: MM-DD HH:MM:SS.mmm PID TID L TAG: MESSAGE
        let pattern = #"^\d{2}-\d{2}\s+(\d{2}:\d{2}:\d{2}\.\d{3})\s+(\d+)\s+(\d+)\s+([VDIWEFA])\s+([^:]+):\s*(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        if let match = regex.firstMatch(in: line, range: range) {
            let nsStr = line as NSString
            let time = nsStr.substring(with: match.range(at: 1))
            let pid = nsStr.substring(with: match.range(at: 2))
            let tid = nsStr.substring(with: match.range(at: 3))
            let lvlStr = nsStr.substring(with: match.range(at: 4))
            let tag = nsStr.substring(with: match.range(at: 5)).trimmingCharacters(in: .whitespaces)
            let msg = nsStr.substring(with: match.range(at: 6))
            return LogEntry(time: time, pid: pid, tid: tid, level: LogLevel.from(tag: lvlStr), tag: tag, message: msg)
        }
        
        // Fallback for stack trace continuation
        return LogEntry(time: "", pid: "", tid: "", level: .debug, tag: "", message: line)
    }
    
    var filteredLogs: [LogEntry] {
        let minPriority = logcatLevel.priority
        let query = logcatSearchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        let packageFilter = logcatSelectedPackage
        
        return logs.filter { entry in
            // Filter by Level
            if entry.level.priority < minPriority {
                return false
            }
            
            // Filter by Package (matches PID or package name)
            if packageFilter != "All" {
                if let pkgName = pidPackageMap[entry.pid] {
                    if !pkgName.contains(packageFilter) && !entry.tag.lowercased().contains(packageFilter.lowercased()) {
                        return false
                    }
                } else if !entry.tag.lowercased().contains(packageFilter.lowercased()) {
                    return false
                }
            }
            
            // Filter by search query
            if !query.isEmpty {
                let matchesTag = entry.tag.lowercased().contains(query)
                let matchesMsg = entry.message.lowercased().contains(query)
                let matchesPid = entry.pid.contains(query)
                if !matchesTag && !matchesMsg && !matchesPid {
                    return false
                }
            }
            
            return true
        }
    }
}

// MARK: - Dark Theme Colors (JetBrains & macOS Dark Inspired)

struct AppColors {
    static let darkBg = Color(red: 0.11, green: 0.12, blue: 0.13)       // #1E1F22
    static let toolbarBg = Color(red: 0.16, green: 0.17, blue: 0.18)    // #2B2D30
    static let panelBg = Color(red: 0.08, green: 0.09, blue: 0.10)      // #141517
    static let border = Color(red: 0.22, green: 0.23, blue: 0.25)       // #393B40
    static let textPrimary = Color(red: 0.88, green: 0.89, blue: 0.91)  // #DFE1E5
    static let textSecondary = Color(red: 0.60, green: 0.62, blue: 0.66)// #9DA0A8
    static let accentBlue = Color(red: 0.21, green: 0.45, blue: 0.94)   // #3574F0
    static let accentRed = Color(red: 0.90, green: 0.24, blue: 0.24)    // #E53935
}

// MARK: - Views

struct ContentView: View {
    @StateObject var state = AppState()
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Unified Header Bar
            HStack(spacing: 12) {
                // Device Status & Picker
                HStack(spacing: 7) {
                    Circle()
                        .fill(state.isError ? Color.red : (state.devices.isEmpty ? Color.orange : Color.green))
                        .frame(width: 8, height: 8)
                    
                    if state.devices.isEmpty {
                        Text("Không có thiết bị")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Picker("", selection: $state.selectedDeviceId) {
                            ForEach(state.devices) { dev in
                                Text(dev.displayName).tag(dev.id)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 240, alignment: .leading)
                    }
                    
                    Button(action: { state.refreshDevices() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Làm mới danh sách thiết bị")
                }
                
                Spacer()
                
                // Navigation Tabs
                HStack(spacing: 4) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Button(action: {
                            state.activeTab = tab
                            if tab == .logcat {
                                state.startLogcat()
                            } else {
                                state.stopLogcat()
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 11))
                                Text(tab.rawValue)
                                    .font(.system(size: 12, weight: state.activeTab == tab ? .semibold : .regular))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .foregroundColor(state.activeTab == tab ? .white : AppColors.textSecondary)
                            .background(state.activeTab == tab ? AppColors.accentBlue : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(AppColors.darkBg)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppColors.toolbarBg)
            
            Divider().background(AppColors.border)
            
            // Tab Content
            Group {
                switch state.activeTab {
                case .screenshot:
                    ScreenshotTabView(state: state)
                case .recording:
                    ScreenRecordTabView(state: state)
                case .logcat:
                    LogcatTabView(state: state)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppColors.darkBg)
        .preferredColorScheme(.dark)
        .frame(minWidth: 520, idealWidth: 760, maxWidth: .infinity, minHeight: 560, idealHeight: 660, maxHeight: .infinity)
    }
}

// MARK: - Screenshot Tab

struct ScreenshotTabView: View {
    @ObservedObject var state: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Preview & Canvas Area
            ZStack {
                AppColors.panelBg
                
                if let image = state.lastImage {
                    VStack(spacing: 8) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 24)
                            .padding(.top, 14)
                            .padding(.bottom, 6)
                        
                        HStack(spacing: 12) {
                            Button(action: { state.copyCurrentImageToClipboard() }) {
                                Label("Sao chép lại", systemImage: "doc.on.doc")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            if state.lastSavedURL != nil {
                                Button(action: { state.openLastFileInFinder() }) {
                                    Label("Mở trong Finder", systemImage: "folder")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.bottom, 10)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "iphone.and.arrow.forward")
                            .font(.system(size: 44, weight: .light))
                            .foregroundColor(AppColors.textSecondary.opacity(0.6))
                        
                        Text("Sẵn sàng chụp màn hình ADB")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Ảnh chụp xong sẽ tự động sao chép vào Clipboard.\nNhấn nút bên dưới hoặc phím Space để chụp.")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .frame(maxHeight: .infinity)
                }
                
                // Toast Alert
                if state.showCopiedAlert {
                    VStack {
                        HStack(spacing: 7) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Đã sao chép ảnh vào Clipboard!")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        .padding(.top, 14)
                        
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.showCopiedAlert)
                }
            }
            
            Divider().background(AppColors.border)
            
            // Bottom Action Controls
            VStack(spacing: 12) {
                Button(action: { state.capture() }) {
                    HStack(spacing: 8) {
                        if state.isCapturing {
                            ProgressView()
                                .controlSize(.small)
                                .colorInvert()
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text(state.isCapturing ? "Đang chụp..." : "Chụp Màn Hình (Space)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .foregroundColor(.white)
                    .background(state.devices.isEmpty ? Color.gray : AppColors.accentBlue)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(state.isCapturing || state.devices.isEmpty)
                .keyboardShortcut(.space, modifiers: [])
                
                HStack(spacing: 16) {
                    Toggle("Mặc định vào Clipboard", isOn: $state.copyToClipboard)
                        .font(.system(size: 11))
                    
                    Toggle("Lưu ở Desktop", isOn: $state.saveToDesktop)
                        .font(.system(size: 11))
                    
                    Toggle("Tự chụp khi mở", isOn: $state.autoCaptureOnLaunch)
                        .font(.system(size: 11))
                }
                .toggleStyle(.checkbox)
                .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.toolbarBg)
        }
    }
}

// MARK: - Screen Recording Tab

struct ScreenRecordTabView: View {
    @ObservedObject var state: AppState
    
    var durationFormatted: String {
        let mins = state.recordingDuration / 60
        let secs = state.recordingDuration % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AppColors.panelBg
                
                VStack(spacing: 20) {
                    if state.isRecording {
                        // Pulsing recording indicator
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.accentRed.opacity(0.2))
                                    .frame(width: 84, height: 84)
                                Circle()
                                    .fill(AppColors.accentRed)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: AppColors.accentRed.opacity(0.8), radius: 10)
                            }
                            
                            VStack(spacing: 4) {
                                Text(durationFormatted)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text("Đang quay màn hình thiết bị Android...")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    } else if state.isProcessingRecord {
                        VStack(spacing: 14) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Đang kết xuất và lưu video MP4...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    } else if let videoURL = state.lastRecordedURL {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 54))
                                .foregroundColor(.green)
                            
                            VStack(spacing: 5) {
                                Text("Quay màn hình hoàn tất!")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(videoURL.lastPathComponent)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            HStack(spacing: 14) {
                                Button(action: {
                                    NSWorkspace.shared.activateFileViewerSelecting([videoURL])
                                }) {
                                    Label("Mở trong Finder", systemImage: "folder")
                                        .font(.system(size: 13))
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button(action: {
                                    NSWorkspace.shared.open(videoURL)
                                }) {
                                    Label("Xem video", systemImage: "play.fill")
                                        .font(.system(size: 13))
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    } else {
                        VStack(spacing: 14) {
                            Image(systemName: "video.badge.plus")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(AppColors.textSecondary.opacity(0.6))
                            
                            Text("Quay video màn hình Android (Screen Record)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Hỗ trợ quay lên đến 3 phút với tốc độ 12Mbps mượt mà.\nFile video MP4 sẽ tự động lưu ra Desktop và sao chép vào Clipboard.")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            
            Divider().background(AppColors.border)
            
            // Record Action Controls
            VStack(spacing: 12) {
                Button(action: { state.toggleRecording() }) {
                    HStack(spacing: 8) {
                        Image(systemName: state.isRecording ? "stop.fill" : "record.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text(state.isRecording ? "Dừng Quay (\(durationFormatted))" : "Bắt Đầu Quay Video")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .foregroundColor(.white)
                    .background(state.isRecording ? AppColors.accentRed : (state.devices.isEmpty ? Color.gray : AppColors.accentBlue))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(state.devices.isEmpty || state.isProcessingRecord)
                
                HStack {
                    Text("Chất lượng: 12 Mbps (MP4)")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("Tự động sao chép file vào Clipboard")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.toolbarBg)
        }
    }
}

// MARK: - Logcat Tab (Android Studio Style)

struct LogcatTabView: View {
    @ObservedObject var state: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Android Studio Logcat Toolbar
            HStack(spacing: 8) {
                // Package / Process Filter
                HStack(spacing: 4) {
                    Text("Package:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Picker("", selection: $state.logcatSelectedPackage) {
                        ForEach(state.runningPackages, id: \.self) { pkg in
                            Text(pkg == "All" ? "Tất cả tiến trình" : pkg).tag(pkg)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: 160)
                }
                
                // Log Level Filter
                HStack(spacing: 4) {
                    Text("Level:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Picker("", selection: $state.logcatLevel) {
                        ForEach(LogLevel.allCases) { lvl in
                            Text(lvl.rawValue).tag(lvl)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 95)
                }
                
                // Search Query Box
                HStack(spacing: 5) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("Lọc tag, thông điệp, PID...", text: $state.logcatSearchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textPrimary)
                    
                    if !state.logcatSearchQuery.isEmpty {
                        Button(action: { state.logcatSearchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColors.darkBg)
                .cornerRadius(5)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppColors.border, lineWidth: 1))
                .frame(maxWidth: .infinity)
                
                // Action Buttons (Clear, Pause, Scroll, Copy)
                HStack(spacing: 4) {
                    Button(action: { state.clearLogcat() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Xóa sạch logcat (Clear)")
                    .padding(5)
                    
                    Button(action: { state.isLogcatPaused.toggle() }) {
                        Image(systemName: state.isLogcatPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 12))
                            .foregroundColor(state.isLogcatPaused ? .yellow : AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help(state.isLogcatPaused ? "Tiếp tục luồng log" : "Tạm dừng luồng log")
                    .padding(5)
                    
                    Button(action: { state.autoScrollLogcat.toggle() }) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 12))
                            .foregroundColor(state.autoScrollLogcat ? AppColors.accentBlue : AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Tự động cuộn xuống dòng mới nhất")
                    .padding(5)
                    
                    Button(action: {
                        let text = state.filteredLogs.map { "\($0.time) \($0.pid) \($0.level.shortTag) \($0.tag): \($0.message)" }.joined(separator: "\n")
                        let p = NSPasteboard.general
                        p.clearContents()
                        p.setString(text, forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Sao chép toàn bộ log đang lọc")
                    .padding(5)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.toolbarBg)
            
            Divider().background(AppColors.border)
            
            // Log Entries List
            let displayLogs = state.filteredLogs
            
            ScrollViewReader { proxy in
                ScrollView([.vertical, .horizontal]) {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(displayLogs) { entry in
                            LogcatRow(entry: entry)
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .background(AppColors.panelBg)
                .onChange(of: displayLogs.count) { _ in
                    if state.autoScrollLogcat, let last = displayLogs.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            
            Divider().background(AppColors.border)
            
            // Logcat Status Bar
            HStack(spacing: 12) {
                Text("\(displayLogs.count) dòng log")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(AppColors.textSecondary)
                
                if state.isLogcatPaused {
                    Text("• ĐÃ TẠM DỪNG")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                Text("Bộ đệm tối đa: 2500 dòng")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textSecondary.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppColors.toolbarBg)
        }
    }
}

// MARK: - Logcat Row (Android Studio Log Format)

struct LogcatRow: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Timestamp
            if !entry.time.isEmpty {
                Text(entry.time)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))
                    .frame(width: 82, alignment: .leading)
            }
            
            // PID
            if !entry.pid.isEmpty {
                Text(entry.pid)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
                    .frame(width: 44, alignment: .trailing)
            }
            
            // Level Badge
            Text(entry.level.shortTag)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(width: 16, height: 16)
                .background(entry.level.color)
                .cornerRadius(3)
            
            // Tag
            if !entry.tag.isEmpty {
                Text(entry.tag)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(entry.level.color)
                    .frame(maxWidth: 140, alignment: .leading)
                    .lineLimit(1)
            }
            
            // Message
            Text(entry.message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(entry.level == .error || entry.level == .assert ? AppColors.accentRed : AppColors.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 1)
    }
}

// MARK: - App Main

@main
struct AdbStudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
