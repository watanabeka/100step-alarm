import AudioToolbox
import AVFoundation
import Foundation

@Observable
class AudioService {
    private var audioPlayer: AVAudioPlayer?
    private var systemSoundTimer: Timer?

    var isPlaying: Bool = false
    var errorMessage: String?

    /// オーディオセッションのセットアップ
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            errorMessage = "Audio session setup failed: \(error.localizedDescription)"
        }
    }

    /// アラーム音を再生（無限ループ）
    func play(soundName: String) {
        // まず.cafを試し、なければ.m4aを試す
        var url = Bundle.main.url(forResource: soundName, withExtension: "caf")
        if url == nil {
            url = Bundle.main.url(forResource: soundName, withExtension: "m4a")
        }

        // デフォルトのシステムサウンドにフォールバック
        if url == nil {
            url = Bundle.main.url(forResource: "default_alarm", withExtension: "caf")
        }

        guard let soundURL = url else {
            errorMessage = "Sound file not found: \(soundName)"
            // サウンドファイルがない場合はシステムサウンドを使用
            playSystemSound()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1  // 無限ループ
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            errorMessage = "Audio playback failed: \(error.localizedDescription)"
            playSystemSound()
        }
    }

    /// システムサウンドをフォールバックとして再生（ループ用タイマー付き）
    private func playSystemSound() {
        isPlaying = true
        // 即座に再生開始
        AudioServicesPlaySystemSound(1005)

        // 2秒ごとにシステムサウンドを繰り返す
        systemSoundTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard self?.isPlaying == true else {
                self?.systemSoundTimer?.invalidate()
                return
            }
            AudioServicesPlaySystemSound(1005)
        }
    }

    /// 再生を停止
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        systemSoundTimer?.invalidate()
        systemSoundTimer = nil
        isPlaying = false
    }

    /// 利用可能なアラーム音のリスト
    static var availableSounds: [String] {
        [
            "default_alarm",
            "gentle_morning",
            "digital_beep",
            "nature_birds",
            "energetic_beat"
        ]
    }

    /// サウンド名の表示用ラベル
    static func displayName(for soundName: String) -> String {
        switch soundName {
        case "default_alarm": return "デフォルト"
        case "gentle_morning": return "やさしい朝"
        case "digital_beep": return "デジタル"
        case "nature_birds": return "鳥のさえずり"
        case "energetic_beat": return "エナジー"
        default: return soundName
        }
    }
}
