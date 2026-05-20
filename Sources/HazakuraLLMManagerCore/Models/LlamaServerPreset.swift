import Foundation

public enum LlamaServerPresetIntent: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case standard
    case qwenRecommended
    case gemmaRecommended
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
        standard,
        qwenRecommended,
        gemmaRecommended
    ]

    public static let standard = LlamaServerPreset(
        intent: .standard,
        displayName: "Standard",
        contextSize: 32768,
        threads: "auto",
        gpuLayers: "auto"
    )

    public static let qwenRecommended = LlamaServerPreset(
        intent: .qwenRecommended,
        displayName: "Qwen Recommended",
        contextSize: 131072,
        threads: "auto",
        gpuLayers: "auto",
        additionalArguments: ["--flash-attn", "auto", "--cache-type-k", "q8_0", "--cache-type-v", "q8_0"]
    )

    public static let gemmaRecommended = LlamaServerPreset(
        intent: .gemmaRecommended,
        displayName: "Gemma Recommended",
        contextSize: 32768,
        threads: "auto",
        gpuLayers: "auto",
        additionalArguments: ["--flash-attn", "auto", "--cache-type-k", "q8_0", "--cache-type-v", "q8_0"]
    )

    public static func preset(for intent: LlamaServerPresetIntent) -> LlamaServerPreset {
        switch intent {
        case .standard:
            return standard
        case .qwenRecommended:
            return qwenRecommended
        case .gemmaRecommended:
            return gemmaRecommended
        }
    }

    public var previewSummary: String {
        let argumentsSummary = additionalArguments.isEmpty
            ? "no added args"
            : "adds \(additionalArguments.joined(separator: " "))"
        return "Sets context \(contextSize), threads \(threads), GPU layers \(gpuLayers), \(argumentsSummary)."
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
