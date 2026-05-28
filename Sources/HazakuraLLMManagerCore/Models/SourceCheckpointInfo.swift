public struct SourceCheckpointInfo: Equatable, Sendable {
    public let identifier: String
    public let includesPackagedAppArtifact: Bool

    public static let current = SourceCheckpointInfo(
        identifier: "v1.7.0",
        includesPackagedAppArtifact: false
    )
}
