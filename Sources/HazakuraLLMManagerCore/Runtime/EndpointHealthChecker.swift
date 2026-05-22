import Foundation

public protocol EndpointHealthChecking: Sendable {
    func check(_ request: EndpointHealthRequest) async -> EndpointHealthStatus
}

public struct EndpointHealthChecker: EndpointHealthChecking, Sendable {
    private let session: URLSession
    private let timeoutInterval: TimeInterval

    public init(
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 2
    ) {
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    public func check(_ request: EndpointHealthRequest) async -> EndpointHealthStatus {
        guard let healthURL = URL(string: request.healthURL) else {
            return .unhealthy(message: "Health check URL is invalid: \(request.healthURL).")
        }

        return await check(healthURL, timeoutInterval: TimeInterval(request.timeoutSeconds))
    }

    public func check(_ healthURL: URL) async -> EndpointHealthStatus {
        await check(healthURL, timeoutInterval: timeoutInterval)
    }

    private func check(_ healthURL: URL, timeoutInterval: TimeInterval) async -> EndpointHealthStatus {
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

            return .unhealthy(
                message: "Health check returned HTTP \(httpResponse.statusCode) from \(healthURL.absoluteString). Confirm the server finished loading the model or inspect runtime logs."
            )
        } catch {
            return .unhealthy(message: failureMessage(for: error, healthURL: healthURL, timeoutInterval: timeoutInterval))
        }
    }

    private func failureMessage(for error: Error, healthURL: URL, timeoutInterval: TimeInterval) -> String {
        guard let urlError = error as? URLError else {
            return "Health check failed: \(error.localizedDescription)"
        }

        switch urlError.code {
        case .cannotConnectToHost:
            return "No server responded at \(healthURL.absoluteString). Start the runtime or verify the configured port."
        case .timedOut:
            return "Health check timed out after \(formattedTimeout(timeoutInterval)) for \(healthURL.absoluteString)."
        default:
            return "Health check failed: \(urlError.localizedDescription)"
        }
    }

    private func formattedTimeout(_ timeoutInterval: TimeInterval) -> String {
        if timeoutInterval.rounded() == timeoutInterval {
            return "\(Int(timeoutInterval)) seconds"
        }

        return "\(timeoutInterval) seconds"
    }
}
