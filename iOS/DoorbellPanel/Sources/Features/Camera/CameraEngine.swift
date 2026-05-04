import AVFoundation

actor CameraEngine {
    enum CameraEngineError: LocalizedError {
        case deviceUnavailable
        case inputCreationFailed
        case inputRejected

        var errorDescription: String? {
            switch self {
            case .deviceUnavailable:
                return "No camera is available on this device."
            case .inputCreationFailed:
                return "The camera input could not be created."
            case .inputRejected:
                return "The capture session rejected the camera input."
            }
        }
    }

    nonisolated(unsafe) let session = AVCaptureSession()

    private var isConfigured = false

    func startSession() throws {
        if !isConfigured {
            try configureSession()
        }

        if !session.isRunning {
            session.startRunning()
        }
    }

    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        for input in session.inputs {
            session.removeInput(input)
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video) else {
            throw CameraEngineError.deviceUnavailable
        }

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: camera)
        } catch {
            throw CameraEngineError.inputCreationFailed
        }

        guard session.canAddInput(input) else {
            throw CameraEngineError.inputRejected
        }

        session.addInput(input)
        isConfigured = true
    }
}

