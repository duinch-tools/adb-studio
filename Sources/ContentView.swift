import SwiftUI

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

