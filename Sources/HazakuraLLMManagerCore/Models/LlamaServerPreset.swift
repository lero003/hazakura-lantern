import Foundation

public enum LlamaServerPresetIntent: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case standard
    case qwenRecommended
    case qwen36MTPM4Max
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
        qwen36MTPM4Max,
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

    public static let qwen36MTPM4Max = LlamaServerPreset(
        intent: .qwen36MTPM4Max,
        displayName: "Qwen 3.6 MTP M4 Max",
        contextSize: 262144,
        threads: "auto",
        gpuLayers: "99",
        additionalArguments: [
            "--spec-type", "draft-mtp",
            "--spec-draft-n-max", "3",
            "--spec-draft-ngl", "99",
            "--parallel", "1",
            "--flash-attn", "off",
            "--cache-type-k", "f16",
            "--cache-type-v", "f16",
            "--temp", "0.6",
            "--top-p", "0.95",
            "--top-k", "20",
            "--repeat-penalty", "1.0"
        ]
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
        case .qwen36MTPM4Max:
            return qwen36MTPM4Max
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
