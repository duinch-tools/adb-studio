import SwiftUI
import AppKit

extension AppState {
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
    

}
