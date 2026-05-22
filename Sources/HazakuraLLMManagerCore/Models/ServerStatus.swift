import Foundation

public enum ServerStatus: String, CaseIterable, Sendable {
    case stopped
    case starting
    case loading
    case running
    case stopping
    case restarting
    case error

    public var title: String {
        switch self {
        case .stopped:
            "Stopped"
        case .starting:
            "Starting"
        case .loading:
            "Loading Model"
        case .running:
            "Running"
        case .stopping:
            "Stopping"
        case .restarting:
            "Restarting"
        case .error:
            "Error"
        }
    }
}
