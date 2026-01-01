import Foundation

@Observable
class EmergencyStopManager {
    static let shared = EmergencyStopManager()

    private let userDefaults = UserDefaults.standard
    private let remainingKey = "emergencyStopRemaining"
    private let lastResetKey = "emergencyStopLastReset"
    private let maxPerMonthKey = "emergencyStopMaxPerMonth"

    var remaining: Int {
        get { userDefaults.integer(forKey: remainingKey) }
        set { userDefaults.set(newValue, forKey: remainingKey) }
    }

    var maxPerMonth: Int {
        get {
            let value = userDefaults.integer(forKey: maxPerMonthKey)
            return value > 0 ? value : 3
        }
        set {
            userDefaults.set(newValue, forKey: maxPerMonthKey)
        }
    }

    private init() {
        resetIfNewMonth()
        if !hasBeenInitialized {
            remaining = maxPerMonth
        }
    }

    private var hasBeenInitialized: Bool {
        userDefaults.object(forKey: remainingKey) != nil
    }

    /// 緊急停止を使用する
    /// - Returns: 使用できた場合はtrue、残り回数がない場合はfalse
    func use() -> Bool {
        guard remaining > 0 else { return false }
        remaining -= 1
        return true
    }

    /// 月が変わっていたらリセット
    private func resetIfNewMonth() {
        let lastReset = userDefaults.object(forKey: lastResetKey) as? Date ?? .distantPast
        let calendar = Calendar.current

        if !calendar.isDate(lastReset, equalTo: Date(), toGranularity: .month) {
            remaining = maxPerMonth
            userDefaults.set(Date(), forKey: lastResetKey)
        }
    }

    /// 手動でリセット（設定画面用）
    func reset() {
        remaining = maxPerMonth
        userDefaults.set(Date(), forKey: lastResetKey)
    }
}
