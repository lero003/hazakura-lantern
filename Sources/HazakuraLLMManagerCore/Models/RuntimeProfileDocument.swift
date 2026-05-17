import Foundation

public struct RuntimeProfileDocument: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let supportedRuntimeKind = "llama-server"
    public static let exportFileSuffix = ".lantern-profile.json"

    public struct LocalFileReference: Equatable, Sendable {
        public enum Role: Equatable, Sendable {
            case runtimeExecutable
            case modelFile

            public var displayName: String {
                switch self {
                case .runtimeExecutable:
                    return "Runtime executable"
                case .modelFile:
                    return "Model file"
                }
            }
        }

        public var role: Role
        public var path: String

        public init(role: Role, path: String) {
            self.role = role
            self.path = path
        }
    }

    public enum ImportError: Error, Equatable, LocalizedError, Sendable {
        case missingSchemaVersion
        case missingRuntimeKind
        case unsupportedSchemaVersion(Int, supportedVersion: Int)
        case unsupportedRuntimeKind(String, supportedRuntimeKind: String)

        public var errorDescription: String? {
            switch self {
            case .missingSchemaVersion:
                return "Runtime profile is missing schemaVersion."
            case .missingRuntimeKind:
                return "Runtime profile is missing runtimeKind."
            case let .unsupportedSchemaVersion(schemaVersion, supportedVersion):
                return "Runtime profile schema version \(schemaVersion) is not supported by this Lantern build; supported version is \(supportedVersion)."
            case let .unsupportedRuntimeKind(runtimeKind, supportedRuntimeKind):
                return "Runtime profile runtime kind \"\(runtimeKind)\" is not supported by this Lantern build; supported kind is \(supportedRuntimeKind)."
            }
        }
    }

    public var schemaVersion: Int
    public var name: String
    public var runtimeKind: String
    public var configuration: RuntimeConfiguration

    public init(
        name: String,
        runtimeKind: String = RuntimeProfileDocument.supportedRuntimeKind,
        configuration: RuntimeConfiguration,
        schemaVersion: Int = RuntimeProfileDocument.currentSchemaVersion
    ) {
        self.schemaVersion = schemaVersion
        self.name = name
        self.runtimeKind = runtimeKind
        self.configuration = configuration
    }

    public var suggestedExportFileName: String {
        RuntimeProfileDocument.suggestedExportFileName(for: name)
    }

    public var localFileReferences: [LocalFileReference] {
        let references: [LocalFileReference] = [
            .init(role: .runtimeExecutable, path: configuration.runtimeExecutablePath),
            .init(role: .modelFile, path: configuration.modelPath)
        ]

        return references.compactMap { reference in
            let trimmedPath = reference.path.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedPath.isEmpty else {
                return nil
            }

            return LocalFileReference(role: reference.role, path: trimmedPath)
        }
    }

    public static func suggestedExportFileName(for profileName: String) -> String {
        let trimmedName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = trimmedName.isEmpty ? "Runtime Profile" : trimmedName
        let allowedScalars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        var sanitizedScalars = String.UnicodeScalarView()
        var lastWasSeparator = false

        for scalar in baseName.unicodeScalars {
            if allowedScalars.contains(scalar) {
                sanitizedScalars.append(scalar)
                lastWasSeparator = false
            } else if !lastWasSeparator {
                sanitizedScalars.append(UnicodeScalar("-"))
                lastWasSeparator = true
            }
        }

        let sanitizedName = String(sanitizedScalars)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".-"))
        let safeName = sanitizedName.isEmpty ? "Runtime-Profile" : sanitizedName

        guard !safeName.hasSuffix(exportFileSuffix) else {
            return safeName
        }

        return "\(safeName)\(exportFileSuffix)"
    }

    public static func isSupportedProfileFileName(_ fileName: String) -> Bool {
        let trimmedFileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedFileName.lowercased().hasSuffix(exportFileSuffix)
    }

    public static func isSupportedProfileFileURL(_ fileURL: URL) -> Bool {
        isSupportedProfileFileName(fileURL.lastPathComponent)
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
        let runtimeKind = try container.decode(String.self, forKey: .runtimeKind)
        guard runtimeKind == RuntimeProfileDocument.supportedRuntimeKind else {
            throw ImportError.unsupportedRuntimeKind(
                runtimeKind,
                supportedRuntimeKind: RuntimeProfileDocument.supportedRuntimeKind
            )
        }

        self.runtimeKind = runtimeKind
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

        guard let runtimeKind = envelope.runtimeKind else {
            throw ImportError.missingRuntimeKind
        }

        guard runtimeKind == supportedRuntimeKind else {
            throw ImportError.unsupportedRuntimeKind(runtimeKind, supportedRuntimeKind: supportedRuntimeKind)
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
        let runtimeKind: String?
    }
}
