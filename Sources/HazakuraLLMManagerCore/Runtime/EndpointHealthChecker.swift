import Foundation

public struct EndpointHealthChecker {
    private let session: URLSession
    private let timeoutInterval: TimeInterval

    public init(
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 2
    ) {
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    public func check(_ healthURL: URL) async -> EndpointHealthStatus {
        var request = URLRequest(url: healthURL)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .unhealthy(message: "Health check did not return an HTTP response.")
            }

            if (200...299).contains(httpResponse.statusCode) {
                return .healthy(statusCode: httpResponse.statusCode)
            }

            return .unhealthy(message: "Health check returned HTTP \(httpResponse.statusCode).")
        } catch {
            return .unhealthy(message: failureMessage(for: error, healthURL: healthURL))
        }
    }

    private func failureMessage(for error: Error, healthURL: URL) -> String {
        guard let urlError = error as? URLError else {
            return "Health check failed: \(error.localizedDescription)"
        }

        switch urlError.code {
        case .cannotConnectToHost:
            return "No server responded at \(healthURL.absoluteString). Start the runtime or verify the configured port."
        case .timedOut:
            return "Health check timed out after \(formattedTimeout) for \(healthURL.absoluteString)."
        default:
            return "Health check failed: \(urlError.localizedDescription)"
        }
    }

    private var formattedTimeout: String {
        if timeoutInterval.rounded() == timeoutInterval {
            return "\(Int(timeoutInterval)) seconds"
        }

        return "\(timeoutInterval) seconds"
    }
}
