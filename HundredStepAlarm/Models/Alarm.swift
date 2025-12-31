import Foundation
import SwiftData

@Model
class Alarm {
    var id: UUID
    var hour: Int           // 0-23
    var minute: Int         // 0-59
    var isEnabled: Bool
    var repeatDays: [Int]   // 0=日, 1=月, ... 6=土。空なら1回限り
    var targetSteps: Int    // デフォルト100
    var soundName: String   // アラーム音ファイル名
    var label: String       // アラームのラベル（オプション）

    init(
        hour: Int = 7,
        minute: Int = 0,
        isEnabled: Bool = true,
        repeatDays: [Int] = [],
        targetSteps: Int = 100,
        soundName: String = "default_alarm",
        label: String = ""
    ) {
        self.id = UUID()
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.targetSteps = targetSteps
        self.soundName = soundName
        self.label = label
    }

    var timeString: String {
        String(format: "%d:%02d", hour, minute)
    }

    var repeatDaysString: String {
        let dayNames = ["日", "月", "火", "水", "木", "金", "土"]
        if repeatDays.isEmpty {
            return "1回のみ"
        }
        if repeatDays.count == 7 {
            return "毎日"
        }
        if repeatDays.sorted() == [1, 2, 3, 4, 5] {
            return "平日"
        }
        if repeatDays.sorted() == [0, 6] {
            return "週末"
        }
        return repeatDays.sorted().map { dayNames[$0] }.joined(separator: " ")
    }

    var nextAlarmDate: Date? {
        let calendar = Calendar.current
        let now = Date()

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0

        if repeatDays.isEmpty {
            // 1回限り：今日か明日
            if let todayAlarm = calendar.nextDate(after: now, matching: dateComponents, matchingPolicy: .nextTime) {
                return todayAlarm
            }
        } else {
            // 繰り返し：次の該当曜日を探す
            var nextDates: [Date] = []
            for day in repeatDays {
                var components = dateComponents
                components.weekday = day + 1 // Calendar.weekday は 1=日曜
                if let date = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) {
                    nextDates.append(date)
                }
            }
            return nextDates.min()
        }

        return nil
    }
}
