import UserNotifications
import Foundation

class NotificationService {
    static let shared = NotificationService()

    /// 連続通知の数（30秒×10回＝5分間鳴り続ける）
    private let repeatCount = 10

    private init() {}

    /// 通知の許可をリクエスト
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    /// 通知の許可状態を確認
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// アラームをスケジュール
    func scheduleAlarm(_ alarm: Alarm) {
        // 既存の通知をキャンセル
        cancelAlarm(alarm)

        guard alarm.isEnabled else { return }

        // 繰り返し設定がない場合（1回限り）
        if alarm.repeatDays.isEmpty {
            scheduleOneTimeAlarm(alarm)
        } else {
            // 曜日ごとにスケジュール
            for day in alarm.repeatDays {
                scheduleRepeatingAlarm(alarm, weekday: day + 1) // Calendar.weekdayは1始まり
            }
        }
    }

    /// 1回限りのアラームをスケジュール（30秒間隔で連続通知）
    private func scheduleOneTimeAlarm(_ alarm: Alarm) {
        for i in 0..<repeatCount {
            let content = createNotificationContent(alarm, index: i)

            var dateComponents = DateComponents()
            dateComponents.hour = alarm.hour
            dateComponents.minute = alarm.minute
            dateComponents.second = i * 30  // 30秒間隔

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(alarm.id.uuidString)-\(i)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }

    /// 繰り返しアラームをスケジュール
    private func scheduleRepeatingAlarm(_ alarm: Alarm, weekday: Int) {
        for i in 0..<repeatCount {
            let content = createNotificationContent(alarm, index: i)

            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = alarm.hour
            dateComponents.minute = alarm.minute
            dateComponents.second = i * 30

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(alarm.id.uuidString)-\(weekday)-\(i)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule repeating notification: \(error)")
                }
            }
        }
    }

    /// 通知コンテンツを作成
    private func createNotificationContent(_ alarm: Alarm, index: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        if index == 0 {
            content.title = "⏰ 起きる時間です！"
        } else if index < 3 {
            content.title = "😴 まだ寝てる？"
        } else {
            content.title = "🚨 起きて！"
        }

        content.body = "タップして\(alarm.targetSteps)歩歩きましょう"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("\(alarm.soundName).caf"))
        content.interruptionLevel = .timeSensitive  // 集中モード突破
        content.userInfo = ["alarmId": alarm.id.uuidString]

        if !alarm.label.isEmpty {
            content.subtitle = alarm.label
        }

        return content
    }

    /// アラームの通知をキャンセル
    func cancelAlarm(_ alarm: Alarm) {
        var identifiers: [String] = []

        // 1回限りの通知ID
        for i in 0..<repeatCount {
            identifiers.append("\(alarm.id.uuidString)-\(i)")
        }

        // 曜日繰り返しの通知ID
        for day in 1...7 {
            for i in 0..<repeatCount {
                identifiers.append("\(alarm.id.uuidString)-\(day)-\(i)")
            }
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// すべての通知をキャンセル
    func cancelAllAlarms() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    /// アプリ終了時の警告通知
    func scheduleTerminationWarning() {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ アラームが正常に動作しない可能性"
        content.body = "確実に起きるために、アプリを開いてバックグラウンドに残してください"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "app-terminated-warning",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// 警告通知をキャンセル
    func cancelTerminationWarning() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["app-terminated-warning"]
        )
    }
}
