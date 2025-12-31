import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Alarm.hour) private var alarms: [Alarm]

    @State private var showAddAlarm = false
    @State private var selectedAlarm: Alarm?
    @State private var activeAlarm: Alarm?

    var body: some View {
        NavigationStack {
            Group {
                if alarms.isEmpty {
                    emptyStateView
                } else {
                    alarmListView
                }
            }
            .navigationTitle("100歩目覚まし")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAlarm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showAddAlarm) {
                AlarmEditView(alarm: nil) { newAlarm in
                    modelContext.insert(newAlarm)
                    NotificationService.shared.scheduleAlarm(newAlarm)
                }
            }
            .sheet(item: $selectedAlarm) { alarm in
                AlarmEditView(alarm: alarm) { _ in
                    NotificationService.shared.scheduleAlarm(alarm)
                }
            }
            .fullScreenCover(item: $activeAlarm) { alarm in
                AlarmRingView(alarm: alarm) {
                    activeAlarm = nil
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .alarmTriggered)) { notification in
                if let alarmIdString = notification.userInfo?["alarmId"] as? String,
                   let alarm = alarms.first(where: { $0.id.uuidString == alarmIdString }) {
                    activeAlarm = alarm
                }
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "アラームがありません",
            systemImage: "alarm",
            description: Text("右上の＋ボタンで追加しましょう")
        )
    }

    private var alarmListView: some View {
        List {
            ForEach(alarms) { alarm in
                AlarmRow(alarm: alarm)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAlarm = alarm
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteAlarm(alarm)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    private func deleteAlarm(_ alarm: Alarm) {
        NotificationService.shared.cancelAlarm(alarm)
        modelContext.delete(alarm)
    }
}

struct AlarmRow: View {
    @Bindable var alarm: Alarm

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundStyle(alarm.isEnabled ? .primary : .secondary)

                HStack(spacing: 8) {
                    Label("\(alarm.targetSteps)歩", systemImage: "figure.walk")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)

                    Text(alarm.repeatDaysString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !alarm.label.isEmpty {
                        Text(alarm.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: $alarm.isEnabled)
                .labelsHidden()
                .onChange(of: alarm.isEnabled) { _, isEnabled in
                    if isEnabled {
                        NotificationService.shared.scheduleAlarm(alarm)
                    } else {
                        NotificationService.shared.cancelAlarm(alarm)
                    }
                }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AlarmListView()
        .modelContainer(for: Alarm.self, inMemory: true)
}
