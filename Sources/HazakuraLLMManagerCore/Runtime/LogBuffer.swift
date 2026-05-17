import Foundation

public struct LogBuffer: Sendable {
    public private(set) var entries: [LogEntry] = []
    public let maxEntries: Int

    public init(maxEntries: Int) {
        self.maxEntries = max(1, maxEntries)
    }

    public mutating func append(_ text: String, stream: LogEntry.Stream) {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)

        if lines.isEmpty {
            entries.append(LogEntry(stream: stream, text: text))
        } else {
            entries.append(contentsOf: lines.map { LogEntry(stream: stream, text: $0) })
        }

        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    public mutating func clear() {
        entries.removeAll()
    }
}
