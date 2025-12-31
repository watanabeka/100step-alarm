import CoreMotion
import Foundation

@Observable
class PedometerService {
    private let pedometer = CMPedometer()

    var currentSteps: Int = 0
    var isTracking: Bool = false
    var errorMessage: String?

    var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    func startCounting() {
        guard isAvailable else {
            errorMessage = "歩数カウントが利用できません"
            return
        }

        currentSteps = 0
        isTracking = true
        errorMessage = nil

        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isTracking = false
                    return
                }

                guard let data = data else { return }
                self?.currentSteps = data.numberOfSteps.intValue
            }
        }
    }

    func stopCounting() {
        pedometer.stopUpdates()
        isTracking = false
    }

    /// シミュレーター用のモック歩数追加
    #if targetEnvironment(simulator)
    func addMockSteps(_ count: Int) {
        currentSteps += count
    }
    #endif
}
