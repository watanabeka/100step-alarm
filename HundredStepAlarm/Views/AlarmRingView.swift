import SwiftUI

struct AlarmRingView: View {
    let alarm: Alarm
    let onDismiss: () -> Void

    @State private var pedometerService = PedometerService()
    @State private var audioService = AudioService()
    @State private var showEmergencyConfirm = false
    @State private var isCompleted = false

    private var emergencyManager: EmergencyStopManager { .shared }

    private var progress: Double {
        guard alarm.targetSteps > 0 else { return 1.0 }
        return min(Double(pedometerService.currentSteps) / Double(alarm.targetSteps), 1.0)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [progressColor.opacity(0.3), progressColor.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // 現在時刻
                Text(Date(), style: .time)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                // 歩数カウンター（メイン）
                stepCounterView

                // プログレスバー
                progressBarView

                Spacer()

                // 緊急停止ボタン
                emergencyStopButton

                // シミュレーター用のデバッグボタン
                #if targetEnvironment(simulator)
                debugButtons
                #endif
            }
            .padding()

            // 達成時のオーバーレイ
            if isCompleted {
                CompletionOverlay(onDismiss: onDismiss)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            startAlarm()
        }
        .onDisappear {
            stopAlarm()
        }
        .onChange(of: pedometerService.currentSteps) { _, newValue in
            if newValue >= alarm.targetSteps && !isCompleted {
                completeAlarm()
            }
        }
        .confirmationDialog(
            "緊急停止しますか？",
            isPresented: $showEmergencyConfirm,
            titleVisibility: .visible
        ) {
            Button("停止する（残り\(emergencyManager.remaining - 1)回になります）", role: .destructive) {
                if emergencyManager.use() {
                    stopAlarm()
                    onDismiss()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("緊急停止は月に\(emergencyManager.maxPerMonth)回までです。本当に使用しますか？")
        }
    }

    private var stepCounterView: some View {
        VStack(spacing: 8) {
            Text("\(pedometerService.currentSteps)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(progressColor)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: pedometerService.currentSteps)

            Text("/ \(alarm.targetSteps) 歩")
                .font(.title2)
                .foregroundStyle(.secondary)

            if let error = pedometerService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var progressBarView: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)

                    // 進捗
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 16)
                        .animation(.spring(duration: 0.3), value: progress)
                }
            }
            .frame(height: 16)

            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 40)
    }

    private var emergencyStopButton: some View {
        Button {
            showEmergencyConfirm = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                Text("緊急停止")
                    .font(.caption)
                Text("残り \(emergencyManager.remaining) 回")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(emergencyManager.remaining > 0 ? .white.opacity(0.8) : .gray)
        .disabled(emergencyManager.remaining <= 0)
        .padding(.bottom, 40)
    }

    #if targetEnvironment(simulator)
    private var debugButtons: some View {
        HStack(spacing: 16) {
            Button("+10歩") {
                pedometerService.addMockSteps(10)
            }
            .buttonStyle(.bordered)

            Button("+50歩") {
                pedometerService.addMockSteps(50)
            }
            .buttonStyle(.bordered)

            Button("達成") {
                pedometerService.addMockSteps(alarm.targetSteps - pedometerService.currentSteps)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.bottom, 20)
    }
    #endif

    private func startAlarm() {
        audioService.setupAudioSession()
        audioService.play(soundName: alarm.soundName)
        pedometerService.startCounting()
    }

    private func stopAlarm() {
        audioService.stop()
        pedometerService.stopCounting()
    }

    private func completeAlarm() {
        withAnimation(.spring(duration: 0.5)) {
            isCompleted = true
        }
        stopAlarm()

        // 振動フィードバック
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct CompletionOverlay: View {
    let onDismiss: () -> Void

    @State private var showAnimation = false

    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.white)
                    .scaleEffect(showAnimation ? 1.0 : 0.5)
                    .opacity(showAnimation ? 1.0 : 0.0)

                Text("おはようございます！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .opacity(showAnimation ? 1.0 : 0.0)

                Text("今日も良い1日を")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .opacity(showAnimation ? 1.0 : 0.0)

                Button("閉じる") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.green)
                .padding(.top, 20)
                .opacity(showAnimation ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6).delay(0.1)) {
                showAnimation = true
            }
        }
    }
}

#Preview {
    AlarmRingView(
        alarm: Alarm(hour: 7, minute: 0, targetSteps: 100)
    ) {}
}
