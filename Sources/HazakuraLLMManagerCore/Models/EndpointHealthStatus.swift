import Foundation

public enum EndpointHealthStatus: Equatable, Sendable {
    case unchecked
    case checking
    case healthy(statusCode: Int)
    case unhealthy(message: String)

    public var title: String {
        switch self {
        case .unchecked:
            "Not checked"
        case .checking:
            "Checking"
        case .healthy(let statusCode):
            "Healthy (HTTP \(statusCode))"
        case .unhealthy:
            "Unhealthy"
        }
    }

    public var detail: String? {
        switch self {
        case .unchecked:
            "Run a manual check after the server is started."
        case .checking:
            "Requesting the local health endpoint..."
        case .healthy:
            "The health endpoint returned a successful response."
        case .unhealthy(let message):
            message
        }
    }

    public var systemImageName: String {
        switch self {
        case .unchecked:
            "questionmark.circle"
        case .checking:
            "clock"
        case .healthy:
            "checkmark.circle"
        case .unhealthy:
            "exclamationmark.triangle"
        }
    }

    public var tone: EndpointHealthStatusTone {
        switch self {
        case .unchecked:
            .neutral
        case .checking:
            .inProgress
        case .healthy:
            .success
        case .unhealthy:
            .failure
        }
    }
}

public enum EndpointHealthStatusTone: Equatable, Sendable {
    case neutral
    case inProgress
    case success
    case failure
}
