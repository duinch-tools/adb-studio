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

