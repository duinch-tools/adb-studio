import SwiftUI

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

