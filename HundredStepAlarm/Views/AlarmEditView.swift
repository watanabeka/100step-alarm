import SwiftUI

struct AlarmEditView: View {
    @Environment(\.dismiss) private var dismiss

    let alarm: Alarm?
    let onSave: (Alarm) -> Void

    @State private var hour: Int
    @State private var minute: Int
    @State private var targetSteps: Int
    @State private var repeatDays: Set<Int>
    @State private var soundName: String
    @State private var label: String

    private let stepOptions = [50, 75, 100, 125, 150, 175, 200]

    init(alarm: Alarm?, onSave: @escaping (Alarm) -> Void) {
        self.alarm = alarm
        self.onSave = onSave

        _hour = State(initialValue: alarm?.hour ?? 7)
        _minute = State(initialValue: alarm?.minute ?? 0)
        _targetSteps = State(initialValue: alarm?.targetSteps ?? 100)
        _repeatDays = State(initialValue: Set(alarm?.repeatDays ?? []))
        _soundName = State(initialValue: alarm?.soundName ?? "default_alarm")
        _label = State(initialValue: alarm?.label ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // 時刻セクション
                Section {
                    timePickerView
                }

                // 歩数セクション
                Section {
                    Picker("目標歩数", selection: $targetSteps) {
                        ForEach(stepOptions, id: \.self) { steps in
                            Text("\(steps)歩").tag(steps)
                        }
                    }
                } header: {
                    Text("目標歩数")
                } footer: {
                    Text("アラームを止めるために歩く歩数です")
                }

                // 繰り返しセクション
                Section("繰り返し") {
                    repeatDaysView
                }

                // サウンドセクション
                Section("アラーム音") {
                    Picker("サウンド", selection: $soundName) {
                        ForEach(AudioService.availableSounds, id: \.self) { sound in
                            Text(AudioService.displayName(for: sound)).tag(sound)
                        }
                    }
                }

                // ラベルセクション
                Section("ラベル") {
                    TextField("ラベル（オプション）", text: $label)
                }
            }
            .navigationTitle(alarm == nil ? "アラーム追加" : "アラーム編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveAlarm()
                    }
                }
            }
        }
    }

    private var timePickerView: some View {
        HStack {
            Spacer()
            HStack(spacing: 0) {
                // 時間ピッカー
                Picker("時", selection: $hour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text("\(h)").tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()

                Text(":")
                    .font(.system(size: 32, weight: .light))

                // 分ピッカー
                Picker("分", selection: $minute) {
                    ForEach(0..<60, id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()
            }
            Spacer()
        }
    }

    private var repeatDaysView: some View {
        HStack(spacing: 8) {
            ForEach(Array(zip(0..<7, ["日", "月", "火", "水", "木", "金", "土"])), id: \.0) { day, name in
                DayButton(
                    name: name,
                    isSelected: repeatDays.contains(day),
                    isWeekend: day == 0 || day == 6
                ) {
                    if repeatDays.contains(day) {
                        repeatDays.remove(day)
                    } else {
                        repeatDays.insert(day)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func saveAlarm() {
        if let existingAlarm = alarm {
            existingAlarm.hour = hour
            existingAlarm.minute = minute
            existingAlarm.targetSteps = targetSteps
            existingAlarm.repeatDays = Array(repeatDays)
            existingAlarm.soundName = soundName
            existingAlarm.label = label
            onSave(existingAlarm)
        } else {
            let newAlarm = Alarm(
                hour: hour,
                minute: minute,
                isEnabled: true,
                repeatDays: Array(repeatDays),
                targetSteps: targetSteps,
                soundName: soundName,
                label: label
            )
            onSave(newAlarm)
        }
        dismiss()
    }
}

struct DayButton: View {
    let name: String
    let isSelected: Bool
    let isWeekend: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundStyle(isSelected ? .white : (isWeekend ? .red : .primary))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AlarmEditView(alarm: nil) { _ in }
}
