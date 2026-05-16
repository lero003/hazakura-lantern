import Foundation

public enum ServerStatus: String, CaseIterable, Sendable {
    case stopped
    case starting
    case running
    case stopping
    case error

    public var title: String {
        switch self {
        case .stopped:
            "Stopped"
        case .starting:
            "Starting"
        case .running:
            "Running"
        case .stopping:
            "Stopping"
        case .error:
            "Error"
        }
    }
}
