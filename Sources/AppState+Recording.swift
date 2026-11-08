import SwiftUI
import AppKit

extension AppState {
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
    

}
