import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class CameraSessionController {
    enum State: Equatable {
        case idle
        case requestingPermission
        case configuring
        case running
        case permissionDenied
        case failed(String)
    }

    var state: State = .idle

    @ObservationIgnored private let engine = CameraEngine()

    var previewSession: AVCaptureSession {
        engine.session
    }

    func activate() {
        Task {
            await prepareCameraIfNeeded()
        }
    }

    func deactivate() {
        Task {
            await engine.stopSession()

            switch state {
            case .permissionDenied, .failed:
                break
            default:
                state = .idle
            }
        }
    }

    private func prepareCameraIfNeeded() async {
        switch state {
        case .requestingPermission, .configuring, .running:
            return
        default:
            break
        }

        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authorizationStatus {
        case .authorized:
            await startSession()
        case .notDetermined:
            state = .requestingPermission
            let granted = await requestAccess()
            guard granted else {
                state = .permissionDenied
                return
            }
            await startSession()
        case .denied, .restricted:
            state = .permissionDenied
        @unknown default:
            state = .failed("An unknown camera authorization state was returned.")
        }
    }

    private func startSession() async {
        state = .configuring

        do {
            try await engine.startSession()
            state = .running
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

