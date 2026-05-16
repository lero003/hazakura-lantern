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
            .map(ShellQuoter.quote)
            .joined(separator: " ")
    }
}
