import Foundation

public struct EndpointHealthRequest: Equatable, Sendable {
    public var healthURL: String

    public init(healthURL: String) {
        self.healthURL = healthURL
    }

    public var curlCommand: String {
        "curl -fsS \(ShellQuoter.quote(healthURL))"
    }
}
