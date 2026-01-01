import SwiftUI

struct SettingsView: View {
    @State private var showResetConfirm = false
    @State private var notificationStatus: String = "確認中..."

    private var emergencyManager: EmergencyStopManager { .shared }

    var body: some View {
        Form {
            // 緊急停止設定
            Section {
                HStack {
                    Text("今月の残り回数")
                    Spacer()
                    Text("\(emergencyManager.remaining) / \(emergencyManager.maxPerMonth)")
                        .foregroundStyle(.secondary)
                }

                Stepper(
                    "月の上限回数: \(emergencyManager.maxPerMonth)",
                    value: Binding(
                        get: { emergencyManager.maxPerMonth },
                        set: { emergencyManager.maxPerMonth = $0 }
                    ),
                    in: 1...10
                )
            } header: {
                Text("緊急停止")
            } footer: {
                Text("緊急停止は、どうしてもアラームを止めたい時のための機能です。毎月1日にリセットされます。")
            }

            // 通知設定
            Section {
                HStack {
                    Text("通知の許可")
                    Spacer()
                    Text(notificationStatus)
                        .foregroundStyle(.secondary)
                }

                Button("通知設定を開く") {
                    openNotificationSettings()
                }
            } header: {
                Text("通知")
            } footer: {
                Text("アラームを確実に鳴らすために、通知を許可してください。")
            }

            // アプリについて
            Section("アプリについて") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text(Bundle.main.appVersion)
                        .foregroundStyle(.secondary)
                }

                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text("プライバシーポリシー")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)

                Link(destination: URL(string: "https://example.com/terms")!) {
                    HStack {
                        Text("利用規約")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }

            // ヒントセクション
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    tipRow(
                        icon: "bell.badge",
                        title: "通知を許可する",
                        description: "設定 → 通知 → 100歩目覚まし"
                    )

                    tipRow(
                        icon: "moon.fill",
                        title: "集中モードでも通知",
                        description: "集中モードの設定で通知を許可してください"
                    )

                    tipRow(
                        icon: "app.badge",
                        title: "アプリを終了しない",
                        description: "バックグラウンドに残しておくと確実です"
                    )
                }
            } header: {
                Text("確実に起きるためのヒント")
            }

            // デバッグセクション（開発用）
            #if DEBUG
            Section("デバッグ") {
                Button("緊急停止をリセット") {
                    showResetConfirm = true
                }

                Button("すべての通知をキャンセル") {
                    NotificationService.shared.cancelAllAlarms()
                }
            }
            #endif
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await checkNotificationStatus()
        }
        .confirmationDialog(
            "緊急停止の回数をリセットしますか？",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("リセット", role: .destructive) {
                emergencyManager.reset()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private func tipRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func checkNotificationStatus() async {
        let status = await NotificationService.shared.checkPermissionStatus()
        switch status {
        case .authorized:
            notificationStatus = "許可済み"
        case .denied:
            notificationStatus = "拒否"
        case .notDetermined:
            notificationStatus = "未設定"
        case .provisional:
            notificationStatus = "仮許可"
        case .ephemeral:
            notificationStatus = "一時的"
        @unknown default:
            notificationStatus = "不明"
        }
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
