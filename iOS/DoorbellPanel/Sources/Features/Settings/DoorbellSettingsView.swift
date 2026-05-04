import SwiftUI

struct DoorbellSettingsView: View {
    @Bindable var viewModel: DoorbellViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("HomeKit bridge") {
                    TextField("Webhook URL", text: $viewModel.bridgeWebhookURL, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    Text("Example: http://homebridge.local:51849/doorbell/ring")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("How this works") {
                    Text("The app handles the camera locally. When you press the ring button, it can also POST to the Homebridge webhook so HomeKit receives a matching virtual doorbell event.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
