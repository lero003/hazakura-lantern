import Foundation

public struct RecentRuntimePaths: Codable, Equatable, Sendable {
    public var runtimeExecutablePaths: [String]
    public var modelPaths: [String]

    public init(runtimeExecutablePaths: [String] = [], modelPaths: [String] = []) {
        self.runtimeExecutablePaths = runtimeExecutablePaths
        self.modelPaths = modelPaths
    }

    public static let empty = RecentRuntimePaths()
}
