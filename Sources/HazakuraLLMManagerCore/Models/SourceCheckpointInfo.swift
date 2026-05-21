public struct SourceCheckpointInfo: Equatable, Sendable {
    public let identifier: String
    public let includesPackagedAppArtifact: Bool

    public static let current = SourceCheckpointInfo(
        identifier: "v0.9.0-alpha.1",
        includesPackagedAppArtifact: false
    )
}
