import Foundation

public enum LlamaServerPresetIntent: String, CaseIterable, Codable, Equatable, Sendable {
    case conservative
    case balancedLocal
    case longContext
    case lowMemory
    case mtpCapable
}

public struct LlamaServerPreset: Equatable, Sendable {
    public let intent: LlamaServerPresetIntent
    public let displayName: String
    public let contextSize: Int
    public let threads: String
    public let gpuLayers: String
    public let additionalArguments: [String]

    public init(
        intent: LlamaServerPresetIntent,
        displayName: String,
        contextSize: Int,
        threads: String,
        gpuLayers: String,
        additionalArguments: [String] = []
    ) {
        self.intent = intent
        self.displayName = displayName
        self.contextSize = contextSize
        self.threads = threads
        self.gpuLayers = gpuLayers
        self.additionalArguments = additionalArguments
    }

    public static let all: [LlamaServerPreset] = [
        conservative,
        balancedLocal,
        longContext,
        lowMemory,
        mtpCapable
    ]

    public static let conservative = LlamaServerPreset(
        intent: .conservative,
        displayName: "Conservative",
        contextSize: 4096,
        threads: "auto",
        gpuLayers: "auto"
    )

    public static let balancedLocal = LlamaServerPreset(
        intent: .balancedLocal,
        displayName: "Balanced Local",
        contextSize: 8192,
        threads: "auto",
        gpuLayers: "auto"
    )

    public static let longContext = LlamaServerPreset(
        intent: .longContext,
        displayName: "Long Context",
        contextSize: 32768,
        threads: "auto",
        gpuLayers: "auto",
        additionalArguments: ["--cache-type-k", "q8_0", "--cache-type-v", "q8_0"]
    )

    public static let lowMemory = LlamaServerPreset(
        intent: .lowMemory,
        displayName: "Low Memory",
        contextSize: 4096,
        threads: "auto",
        gpuLayers: "0"
    )

    public static let mtpCapable = LlamaServerPreset(
        intent: .mtpCapable,
        displayName: "MTP Capable",
        contextSize: 8192,
        threads: "auto",
        gpuLayers: "auto",
        additionalArguments: ["--spec-type", "draft-mtp", "--spec-draft-n-max", "16"]
    )

    public static func preset(for intent: LlamaServerPresetIntent) -> LlamaServerPreset {
        switch intent {
        case .conservative:
            return conservative
        case .balancedLocal:
            return balancedLocal
        case .longContext:
            return longContext
        case .lowMemory:
            return lowMemory
        case .mtpCapable:
            return mtpCapable
        }
    }

    public func applying(to configuration: RuntimeConfiguration) -> RuntimeConfiguration {
        var updated = configuration
        updated.contextSize = contextSize
        updated.threads = threads
        updated.gpuLayers = gpuLayers
        updated.additionalArguments = additionalArguments.map(ShellQuoter.quote).joined(separator: " ")
        return updated
    }
}
