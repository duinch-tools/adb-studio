import SwiftUI

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
                .onChange(of: displayLogs.count) {
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

