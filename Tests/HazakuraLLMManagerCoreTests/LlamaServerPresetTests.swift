import XCTest
@testable import HazakuraLLMManagerCore

final class LlamaServerPresetTests: XCTestCase {
    func testPresetVocabularyStaysSmallAndOrdered() {
        XCTAssertEqual(
            LlamaServerPreset.all.map(\.intent),
            [.standard, .qwenRecommended, .qwen36MTPM4Max, .gemmaRecommended]
        )
    }

    func testApplyingPresetKeepsSelectedRuntimeModelAndEndpointVisible() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/opt/llama.cpp/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.host = "192.168.1.12"
        config.port = 9876

        let updated = LlamaServerPreset.standard.applying(to: config)

        XCTAssertEqual(updated.runtimeExecutablePath, "/opt/llama.cpp/bin/llama-server")
        XCTAssertEqual(updated.modelPath, "/Users/kei/Models/qwen.gguf")
        XCTAssertEqual(updated.host, "192.168.1.12")
        XCTAssertEqual(updated.port, 9876)
        XCTAssertEqual(updated.contextSize, 32768)
        XCTAssertEqual(updated.threads, "auto")
        XCTAssertEqual(updated.gpuLayers, "auto")
        XCTAssertEqual(updated.additionalArguments, "")
    }

    func testPresetPreviewSummaryKeepsGeneratedSettingsVisible() {
        XCTAssertEqual(
            LlamaServerPreset.standard.previewSummary,
            "Sets context 32768, threads auto, GPU layers auto, no added args."
        )
        XCTAssertEqual(
            LlamaServerPreset.qwenRecommended.previewSummary,
            "Sets context 131072, threads auto, GPU layers auto, adds --flash-attn auto --cache-type-k q8_0 --cache-type-v q8_0."
        )
        XCTAssertEqual(
            LlamaServerPreset.qwen36MTPM4Max.previewSummary,
            "Sets context 262144, threads auto, GPU layers 99, adds --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-ngl 99 --parallel 1 --flash-attn off --cache-type-k f16 --cache-type-v f16 --temp 0.6 --top-p 0.95 --top-k 20 --repeat-penalty 1.0."
        )
    }

    func testStandardPresetLeavesGPULayersToRuntimeDefault() throws {
        let command = try LlamaServerAdapter().buildLaunchCommand(
            config: configured(LlamaServerPreset.standard)
        )

        XCTAssertFalse(command.arguments.contains("-ngl"))
    }

    func testModelFamilyPresetsAddCacheArgumentsToVisibleLaunchCommand() throws {
        let command = try LlamaServerAdapter().buildLaunchCommand(
            config: configured(LlamaServerPreset.gemmaRecommended)
        )

        XCTAssertTrue(command.arguments.contains("--flash-attn"))
        XCTAssertTrue(command.arguments.contains("--cache-type-k"))
        XCTAssertTrue(command.arguments.contains("q8_0"))
        XCTAssertTrue(command.arguments.contains("--cache-type-v"))
    }

    func testNoPresetAddsSpeculativeDecodingArguments() throws {
        for preset in [LlamaServerPreset.standard, .qwenRecommended, .gemmaRecommended] {
            let command = try LlamaServerAdapter().buildLaunchCommand(config: configured(preset))
            XCTAssertFalse(command.arguments.contains("--spec-type"), "\(preset.displayName) should keep MTP off")
            XCTAssertFalse(command.arguments.contains("--spec-draft-n-max"), "\(preset.displayName) should keep MTP off")
        }
    }

    func testQwen36MTPM4MaxPresetAddsVisibleMTPLaunchArguments() throws {
        let command = try LlamaServerAdapter().buildLaunchCommand(
            config: configured(.qwen36MTPM4Max)
        )

        XCTAssertTrue(command.arguments.contains("-ngl"))
        XCTAssertTrue(command.arguments.contains("99"))
        XCTAssertTrue(command.arguments.contains("--spec-type"))
        XCTAssertTrue(command.arguments.contains("draft-mtp"))
        XCTAssertTrue(command.arguments.contains("--spec-draft-n-max"))
        XCTAssertTrue(command.arguments.contains("--spec-draft-ngl"))
        XCTAssertTrue(command.arguments.contains("--parallel"))
        XCTAssertTrue(command.arguments.contains("--flash-attn"))
        XCTAssertTrue(command.arguments.contains("off"))
        XCTAssertTrue(command.arguments.contains("--cache-type-k"))
        XCTAssertTrue(command.arguments.contains("f16"))
        XCTAssertTrue(command.arguments.contains("--cache-type-v"))
        XCTAssertTrue(command.arguments.contains("--temp"))
        XCTAssertTrue(command.arguments.contains("0.6"))
    }

    private func configured(_ preset: LlamaServerPreset) -> RuntimeConfiguration {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        return preset.applying(to: config)
    }
}
