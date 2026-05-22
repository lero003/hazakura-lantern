public struct SourceCheckpointInfo: Equatable, Sendable {
    public let identifier: String
    public let includesPackagedAppArtifact: Bool

    public static let current = SourceCheckpointInfo(
        identifier: "v1.0.0-rc.2",
        includesPackagedAppArtifact: false
    )
}
