import Foundation

enum DoorbellBridgeDeliveryMode {
    case localOnly
    case homebridgeWebhook
}

enum DoorbellBridgeError: LocalizedError {
    case invalidURL
    case badResponseStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Homebridge webhook URL is invalid."
        case let .badResponseStatus(statusCode):
            return "The Homebridge webhook returned status \(statusCode)."
        }
    }
}

struct DoorbellBridgeClient {
    func ringDoorbell(using webhookURLString: String) async throws -> DoorbellBridgeDeliveryMode {
        let trimmedURL = webhookURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            return .localOnly
        }

        guard let url = URL(string: trimmedURL),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            throw DoorbellBridgeError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 5
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RingPayload(source: "DoorbellPanelApp", event: "ring"))

        let (_, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        guard (200 ..< 300).contains(statusCode) else {
            throw DoorbellBridgeError.badResponseStatus(statusCode)
        }

        return .homebridgeWebhook
    }
}

private struct RingPayload: Encodable {
    let source: String
    let event: String
    let sentAt = Date.now
}

