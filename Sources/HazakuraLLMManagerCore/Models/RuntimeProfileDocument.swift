import Foundation

public struct RuntimeProfileDocument: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public enum ImportError: Error, Equatable, LocalizedError, Sendable {
        case missingSchemaVersion
        case unsupportedSchemaVersion(Int, supportedVersion: Int)

        public var errorDescription: String? {
            switch self {
            case .missingSchemaVersion:
                return "Runtime profile is missing schemaVersion."
            case let .unsupportedSchemaVersion(schemaVersion, supportedVersion):
                return "Runtime profile schema version \(schemaVersion) is not supported by this Lantern build; supported version is \(supportedVersion)."
            }
        }
    }

    public var schemaVersion: Int
    public var name: String
    public var runtimeKind: String
    public var configuration: RuntimeConfiguration

    public init(
        name: String,
        runtimeKind: String = "llama-server",
        configuration: RuntimeConfiguration,
        schemaVersion: Int = RuntimeProfileDocument.currentSchemaVersion
    ) {
        self.schemaVersion = schemaVersion
        self.name = name
        self.runtimeKind = runtimeKind
        self.configuration = configuration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)

        guard schemaVersion == RuntimeProfileDocument.currentSchemaVersion else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported runtime profile schema version \(schemaVersion)."
            )
        }

        self.schemaVersion = schemaVersion
        self.name = try container.decode(String.self, forKey: .name)
        self.runtimeKind = try container.decode(String.self, forKey: .runtimeKind)
        self.configuration = try container.decode(RuntimeConfiguration.self, forKey: .configuration)
    }

    public func exportJSONData() throws -> Data {
        try RuntimeProfileDocument.exportJSONEncoder.encode(self)
    }

    public static func importJSONData(_ data: Data) throws -> RuntimeProfileDocument {
        let envelope = try JSONDecoder().decode(SchemaEnvelope.self, from: data)
        guard let schemaVersion = envelope.schemaVersion else {
            throw ImportError.missingSchemaVersion
        }

        guard schemaVersion == currentSchemaVersion else {
            throw ImportError.unsupportedSchemaVersion(schemaVersion, supportedVersion: currentSchemaVersion)
        }

        return try JSONDecoder().decode(RuntimeProfileDocument.self, from: data)
    }

    private static var exportJSONEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes
        ]
        return encoder
    }

    private struct SchemaEnvelope: Decodable {
        let schemaVersion: Int?
    }
}
