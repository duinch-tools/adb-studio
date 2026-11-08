import SwiftUI

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

