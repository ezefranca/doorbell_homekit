import SwiftUI

struct DoorbellView: View {
    @Bindable var viewModel: DoorbellViewModel

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            cameraSurface
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.65), .clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                Spacer()
                bottomPanel
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color.black)
        .task {
            viewModel.activateCamera()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                viewModel.activateCamera()
            default:
                viewModel.deactivateCamera()
            }
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            DoorbellSettingsView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var cameraSurface: some View {
        switch viewModel.cameraController.state {
        case .permissionDenied:
            statusBackground(
                title: "Camera access is off",
                message: "Allow camera access in Settings so this app can behave like a live doorbell panel.",
                buttonTitle: "Open Settings"
            ) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            }
        case let .failed(message):
            statusBackground(
                title: "Camera unavailable",
                message: message,
                buttonTitle: "Open Settings"
            ) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            }
        default:
            CameraPreview(session: viewModel.cameraController.previewSession)
                .overlay(alignment: .center) {
                    switch viewModel.cameraController.state {
                    case .requestingPermission:
                        progressCard(title: "Waiting for camera permission")
                    case .configuring:
                        progressCard(title: "Starting live preview")
                    default:
                        EmptyView()
                    }
                }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Doorbell Panel")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Live preview with ring control")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))
            }

            Spacer()

            Button {
                viewModel.isShowingSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open integration settings")
        }
    }

    private var bottomPanel: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                Label(viewModel.bridgeSummary, systemImage: "house.and.flag.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text(viewModel.ringStatus.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusTint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Button {
                viewModel.ringDoorbell()
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: viewModel.isRinging ? "bell.and.waves.left.and.right.fill" : "bell.fill")
                        .font(.system(size: 34, weight: .bold, design: .rounded))

                    Text(viewModel.isRinging ? "Ringing..." : "Ring Doorbell")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.82, blue: 0.34), Color(red: 0.90, green: 0.63, blue: 0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.25), radius: 30, y: 14)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Sends a ring event locally and forwards it to Homebridge when configured.")
        }
    }

    private var statusTint: Color {
        switch viewModel.ringStatus {
        case .ready:
            return .white.opacity(0.86)
        case .ringing:
            return .yellow
        case .localOnlyDelivered:
            return .mint
        case .homeKitDelivered:
            return .green
        case .failed:
            return .red
        }
    }

    private func progressCard(title: String) -> some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func statusBackground(
        title: String,
        message: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.11, blue: 0.12), Color(red: 0.23, green: 0.12, blue: 0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Image(systemName: "camera.metering.unknown")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)

                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)
            }
            .padding(28)
            .frame(maxWidth: 420)
        }
    }
}

