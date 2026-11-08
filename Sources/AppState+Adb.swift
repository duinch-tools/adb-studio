import SwiftUI
import AppKit

extension AppState {
    
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
    

}
