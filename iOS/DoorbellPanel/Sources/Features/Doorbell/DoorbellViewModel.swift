import Foundation
import Observation

@MainActor
@Observable
final class DoorbellViewModel {
    enum RingStatus: Equatable {
        case ready
        case ringing
        case localOnlyDelivered
        case homeKitDelivered
        case failed(String)

        var title: String {
            switch self {
            case .ready:
                return "Ready"
            case .ringing:
                return "Ringing..."
            case .localOnlyDelivered:
                return "Rang locally"
            case .homeKitDelivered:
                return "Forwarded to HomeKit"
            case let .failed(message):
                return message
            }
        }
    }

    private enum DefaultsKey {
        static let webhookURL = "doorbellPanel.homebridgeWebhookURL"
    }

    let cameraController = CameraSessionController()

    var bridgeWebhookURL: String {
        didSet {
            userDefaults.set(bridgeWebhookURL, forKey: DefaultsKey.webhookURL)
        }
    }

    var isShowingSettings = false
    var isRinging = false
    var ringStatus: RingStatus = .ready

    @ObservationIgnored private let bridgeClient = DoorbellBridgeClient()
    @ObservationIgnored private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.bridgeWebhookURL = userDefaults.string(forKey: DefaultsKey.webhookURL) ?? ""
    }

    var bridgeSummary: String {
        bridgeWebhookURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Local preview only"
            : "HomeKit webhook configured"
    }

    func activateCamera() {
        cameraController.activate()
    }

    func deactivateCamera() {
        cameraController.deactivate()
    }

    func ringDoorbell() {
        guard !isRinging else {
            return
        }

        isRinging = true
        ringStatus = .ringing

        Task {
            do {
                let mode = try await bridgeClient.ringDoorbell(using: bridgeWebhookURL)
                switch mode {
                case .localOnly:
                    ringStatus = .localOnlyDelivered
                case .homebridgeWebhook:
                    ringStatus = .homeKitDelivered
                }
            } catch {
                ringStatus = .failed(error.localizedDescription)
            }

            try? await Task.sleep(for: .seconds(1.1))
            isRinging = false
        }
    }
}

