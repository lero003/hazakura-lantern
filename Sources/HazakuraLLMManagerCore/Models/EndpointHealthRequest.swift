import Foundation

public struct EndpointHealthRequest: Equatable, Sendable {
    public var healthURL: String
    public var timeoutSeconds: Int

    public init(healthURL: String, timeoutSeconds: Int = 5) {
        self.healthURL = healthURL
        self.timeoutSeconds = max(1, timeoutSeconds)
    }

    public var curlCommand: String {
        "curl -fsS --max-time \(timeoutSeconds) \(ShellQuoter.quote(healthURL))"
    }
}
