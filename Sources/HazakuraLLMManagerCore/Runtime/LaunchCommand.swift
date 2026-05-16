import Foundation

public struct LaunchCommand: Equatable, Sendable {
    public var executablePath: String
    public var arguments: [String]

    public init(executablePath: String, arguments: [String]) {
        self.executablePath = executablePath
        self.arguments = arguments
    }

    public var displayString: String {
        ([executablePath] + arguments)
            .map(Self.shellQuoted)
            .joined(separator: " ")
    }

    private static func shellQuoted(_ value: String) -> String {
        guard !value.isEmpty else {
            return "''"
        }

        let safeCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_+-=.,/:")
        if value.unicodeScalars.allSatisfy({ safeCharacters.contains($0) }) {
            return value
        }

        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
