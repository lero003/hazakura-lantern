import XCTest
@testable import HazakuraLLMManagerCore

final class LlamaServerPresetTests: XCTestCase {
    func testPresetVocabularyStaysSmallAndOrdered() {
        XCTAssertEqual(
            LlamaServerPreset.all.map(\.intent),
            [.conservative, .balancedLocal, .longContext, .lowMemory, .mtpCapable]
        )
    }

    func testApplyingPresetKeepsSelectedRuntimeModelAndEndpointVisible() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/opt/llama.cpp/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.host = "192.168.1.12"
        config.port = 9876

        let updated = LlamaServerPreset.balancedLocal.applying(to: config)

        XCTAssertEqual(updated.runtimeExecutablePath, "/opt/llama.cpp/bin/llama-server")
        XCTAssertEqual(updated.modelPath, "/Users/kei/Models/qwen.gguf")
        XCTAssertEqual(updated.host, "192.168.1.12")
        XCTAssertEqual(updated.port, 9876)
        XCTAssertEqual(updated.contextSize, 8192)
        XCTAssertEqual(updated.threads, "auto")
        XCTAssertEqual(updated.gpuLayers, "auto")
        XCTAssertEqual(updated.additionalArguments, "")
    }

    func testPresetPreviewSummaryKeepsGeneratedSettingsVisible() {
        XCTAssertEqual(
            LlamaServerPreset.lowMemory.previewSummary,
            "Sets context 4096, threads auto, GPU layers 0, no added args."
        )
        XCTAssertEqual(
            LlamaServerPreset.mtpCapable.previewSummary,
            "Sets context 8192, threads auto, GPU layers auto, adds --spec-type draft-mtp --spec-draft-n-max 16."
        )
    }

    func testLowMemoryPresetKeepsGPULayersCommandVisibleAsZero() throws {
        let command = try LlamaServerAdapter().buildLaunchCommand(
            config: configured(LlamaServerPreset.lowMemory)
        )

        XCTAssertTrue(command.arguments.contains("-ngl"))
        XCTAssertTrue(command.arguments.contains("0"))
    }

    func testLongContextPresetAddsCacheArgumentsToVisibleLaunchCommand() throws {
        let command = try LlamaServerAdapter().buildLaunchCommand(
            config: configured(LlamaServerPreset.longContext)
        )

        XCTAssertTrue(command.arguments.contains("--cache-type-k"))
        XCTAssertTrue(command.arguments.contains("q8_0"))
        XCTAssertTrue(command.arguments.contains("--cache-type-v"))
    }

    func testOnlyMTPCapablePresetAddsSpeculativeDecodingArguments() throws {
        for preset in LlamaServerPreset.all where preset.intent != .mtpCapable {
            let command = try LlamaServerAdapter().buildLaunchCommand(config: configured(preset))
            XCTAssertFalse(command.arguments.contains("--spec-type"), "\(preset.displayName) should keep MTP off")
            XCTAssertFalse(command.arguments.contains("--spec-draft-n-max"), "\(preset.displayName) should keep MTP off")
        }

        let mtpCommand = try LlamaServerAdapter().buildLaunchCommand(
            config: configured(LlamaServerPreset.mtpCapable)
        )

        XCTAssertTrue(mtpCommand.arguments.contains("--spec-type"))
        XCTAssertTrue(mtpCommand.arguments.contains("draft-mtp"))
        XCTAssertTrue(mtpCommand.arguments.contains("--spec-draft-n-max"))
        XCTAssertTrue(mtpCommand.arguments.contains("16"))
    }

    private func configured(_ preset: LlamaServerPreset) -> RuntimeConfiguration {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        return preset.applying(to: config)
    }
}
