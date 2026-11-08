import SwiftUI
import AppKit

extension AppState {
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
