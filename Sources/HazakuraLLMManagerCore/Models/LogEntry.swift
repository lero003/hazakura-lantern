import Foundation

public struct LogEntry: Identifiable, Equatable, Sendable {
    public enum Stream: String, Sendable {
        case info = "info"
        case stdout = "stdout"
        case stderr = "stderr"
        case error = "error"
    }

    public let id: UUID
    public var date: Date
    public var stream: Stream
    public var text: String

    public init(id: UUID = UUID(), date: Date = Date(), stream: Stream, text: String) {
        self.id = id
        self.date = date
        self.stream = stream
        self.text = text
    }
}
