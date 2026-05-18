import XCTest
@testable import HazakuraLLMManagerCore

final class LlamaServerAdapterTests: XCTestCase {
    func testBuildCommandUsesRequiredLlamaServerArguments() throws {
        let config = RuntimeConfiguration(
            runtimeExecutablePath: "/opt/llama.cpp/llama-server",
            modelPath: "/Users/kei/Models/qwen.gguf",
            host: "127.0.0.1",
            port: 1234,
            contextSize: 32768,
            threads: "auto",
            gpuLayers: "auto",
            additionalArguments: ""
        )

        let command = try LlamaServerAdapter().buildLaunchCommand(config: config)

        XCTAssertEqual(command.executablePath, "/opt/llama.cpp/llama-server")
        XCTAssertEqual(command.arguments, [
            "-m", "/Users/kei/Models/qwen.gguf",
            "--host", "127.0.0.1",
            "--port", "1234",
            "-c", "32768"
        ])
    }

    func testBuildCommandAddsExplicitNumericOptionsAndAdditionalArguments() throws {
        let config = RuntimeConfiguration(
            runtimeExecutablePath: "/usr/local/bin/llama-server",
            modelPath: "/Users/kei/Models/qwen.gguf",
            host: "127.0.0.1",
            port: 8080,
            contextSize: 8192,
            threads: "8",
            gpuLayers: "35",
            additionalArguments: "--alias \"qwen local\""
        )

        let command = try LlamaServerAdapter().buildLaunchCommand(config: config)

        XCTAssertEqual(command.arguments, [
            "-m", "/Users/kei/Models/qwen.gguf",
            "--host", "127.0.0.1",
            "--port", "8080",
            "-c", "8192",
            "-t", "8",
            "-ngl", "35",
            "--alias", "qwen local"
        ])
    }

    func testBuildCommandAllowsZeroGPULayers() throws {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.gpuLayers = "0"

        let command = try LlamaServerAdapter().buildLaunchCommand(config: config)

        XCTAssertTrue(command.arguments.contains("-ngl"))
        XCTAssertEqual(command.arguments.last, "0")
    }

    func testBuildCommandAllowsUppercaseGGUFExtension() throws {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/Qwen.GGUF"

        let command = try LlamaServerAdapter().buildLaunchCommand(config: config)

        XCTAssertEqual(command.arguments[1], "/Users/kei/Models/Qwen.GGUF")
    }

    func testBuildCommandNormalizesBlankHostToDefaultLoopback() throws {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.host = " \n\t "

        let command = try LlamaServerAdapter().buildLaunchCommand(config: config)

        XCTAssertEqual(command.arguments[3], "127.0.0.1")
        XCTAssertEqual(try LlamaServerAdapter().endpoint(config: config).apiBaseURLString, "http://localhost:1234/v1")
    }

    func testBuildCommandTrimsConfiguredHostBeforeLaunch() throws {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.host = "  192.168.1.12  "

        let command = try LlamaServerAdapter().buildLaunchCommand(config: config)

        XCTAssertEqual(command.arguments[3], "192.168.1.12")
        XCTAssertEqual(try LlamaServerAdapter().endpoint(config: config).apiBaseURLString, "http://192.168.1.12:1234/v1")
    }

    func testValidateAcceptsSupportedLlamaServerConfigurationWithoutBuildingCommand() throws {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.threads = "auto"
        config.gpuLayers = "0"

        XCTAssertNoThrow(try LlamaServerAdapter().validate(config: config))
    }

    func testValidateRejectsUnsupportedLlamaServerConfigurationBeforeCommandConstruction() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.threads = "zero"

        XCTAssertThrowsError(try LlamaServerAdapter().validate(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidNumericOption(name: "threads", value: "zero"))
        }
    }

    func testValidateRejectsMalformedAdditionalArgumentsBeforeCommandConstruction() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.additionalArguments = "--alias \"qwen"

        XCTAssertThrowsError(try LlamaServerAdapter().validate(config: config)) { error in
            XCTAssertEqual(error as? CommandLineArgumentTokenizerError, .unterminatedQuote("\""))
        }
    }

    func testValidateLaunchPreconditionsAcceptsExecutableRuntimeAndExistingModel() throws {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }

        let runtime = workspace.appendingPathComponent("llama-server")
        let model = workspace.appendingPathComponent("qwen.gguf")
        try makeExecutableFile(at: runtime)
        FileManager.default.createFile(atPath: model.path, contents: Data())

        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = runtime.path
        config.modelPath = model.path

        XCTAssertNoThrow(try LlamaServerAdapter().validateLaunchPreconditions(config: config, fileManager: .default))
    }

    func testValidateLaunchPreconditionsRejectsNonExecutableRuntimeBeforeProcessRun() throws {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }

        let runtime = workspace.appendingPathComponent("llama-server")
        let model = workspace.appendingPathComponent("qwen.gguf")
        FileManager.default.createFile(atPath: runtime.path, contents: Data())
        FileManager.default.createFile(atPath: model.path, contents: Data())

        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = runtime.path
        config.modelPath = model.path

        XCTAssertThrowsError(try LlamaServerAdapter().validateLaunchPreconditions(config: config, fileManager: .default)) { error in
            XCTAssertEqual(error as? LaunchPreflightError, .runtimeNotExecutable(runtime.path))
        }
    }

    func testValidateLaunchPreconditionsRejectsMissingModelBeforeProcessRun() throws {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }

        let runtime = workspace.appendingPathComponent("llama-server")
        let model = workspace.appendingPathComponent("missing.gguf")
        try makeExecutableFile(at: runtime)

        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = runtime.path
        config.modelPath = model.path

        XCTAssertThrowsError(try LlamaServerAdapter().validateLaunchPreconditions(config: config, fileManager: .default)) { error in
            XCTAssertEqual(error as? LaunchPreflightError, .modelFileMissing(model.path))
        }
    }

    func testDisplayStringPreservesQuotedAdditionalArgumentsAsSinglePreviewTokens() throws {
        let config = RuntimeConfiguration(
            runtimeExecutablePath: "/usr/local/bin/llama-server",
            modelPath: "/Users/kei/Models/qwen.gguf",
            host: "127.0.0.1",
            port: 1234,
            contextSize: 32768,
            threads: "auto",
            gpuLayers: "auto",
            additionalArguments: "--alias \"qwen local\" --note \"owner's model\""
        )

        let command = try LlamaServerAdapter().buildLaunchCommand(config: config)

        XCTAssertEqual(
            command.displayString,
            "/usr/local/bin/llama-server -m /Users/kei/Models/qwen.gguf --host 127.0.0.1 --port 1234 -c 32768 --alias 'qwen local' --note 'owner'\\''s model'"
        )
    }

    func testEndpointURLsUseConfiguredPort() throws {
        var config = RuntimeConfiguration.defaultValue
        config.port = 9876

        let adapter = LlamaServerAdapter()
        let endpoint = try adapter.endpoint(config: config)

        XCTAssertEqual(try adapter.apiBaseURL(config: config), URL(string: "http://localhost:9876/v1"))
        XCTAssertEqual(try adapter.healthCheckURL(config: config), URL(string: "http://localhost:9876/v1/models"))
        XCTAssertEqual(endpoint.apiBaseURLString, "http://localhost:9876/v1")
        XCTAssertEqual(endpoint.endpointHealthCurlCommand, "curl -fsS http://localhost:9876/v1/models")
        XCTAssertTrue(endpoint.aiMobileSmokeCurlCommand.contains("http://localhost:9876/v1/chat/completions"))
    }

    func testEndpointContractKeepsClientReachableHostAndLocalHealthCheckSeparate() throws {
        var config = RuntimeConfiguration.defaultValue
        config.host = "192.168.1.12"
        config.port = 9876

        let endpoint = try LlamaServerAdapter().endpoint(config: config)

        XCTAssertEqual(endpoint.apiBaseURLString, "http://192.168.1.12:9876/v1")
        XCTAssertEqual(
            endpoint.environmentSnippet,
            """
            OPENAI_BASE_URL=http://192.168.1.12:9876/v1
            OPENAI_API_KEY=local
            """
        )
        XCTAssertEqual(endpoint.endpointHealthCurlCommand, "curl -fsS http://localhost:9876/v1/models")
    }

    func testEndpointRejectsInvalidHostWithoutBuildingCommand() {
        var config = RuntimeConfiguration.defaultValue
        config.host = "bad host"

        XCTAssertThrowsError(try LlamaServerAdapter().endpoint(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidHost("bad host"))
        }
    }

    func testValidateRejectsInvalidHostBeforeCommandConstruction() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.host = "http://localhost"

        XCTAssertThrowsError(try LlamaServerAdapter().validate(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidHost("http://localhost"))
        }
    }

    func testLaunchProcessFailureDescriptionIsAdapterOwned() {
        let error = NSError(
            domain: NSPOSIXErrorDomain,
            code: Int(POSIXErrorCode.EACCES.rawValue),
            userInfo: [NSLocalizedDescriptionKey: "Permission denied"]
        )
        let command = LaunchCommand(
            executablePath: "/Users/kei/bin/llama-server",
            arguments: ["-m", "/Users/kei/Models/qwen.gguf"]
        )

        let message = LlamaServerAdapter().describeLaunchProcessFailure(error, command: command)

        XCTAssertEqual(
            message,
            "Runtime process could not start because macOS refused permission for /Users/kei/bin/llama-server. Check that the llama-server binary is executable. System error: Permission denied."
        )
    }

    func testRejectsInvalidPort() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.port = 0

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidPort(0))
        }
    }

    func testRejectsMissingRuntimePath() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "  "
        config.modelPath = "/Users/kei/Models/qwen.gguf"

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .missingRuntimePath)
        }
    }

    func testRejectsMissingModelPath() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "\n\t"

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .missingModelPath)
        }
    }

    func testRejectsUnsupportedModelType() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.bin"

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .unsupportedModelType("/Users/kei/Models/qwen.bin"))
        }
    }

    func testRejectsInvalidContextSize() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.contextSize = 0

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidContextSize(0))
        }
    }

    func testRejectsInvalidThreadCount() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.threads = "0"

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidNumericOption(name: "threads", value: "0"))
        }
    }

    func testRejectsInvalidGPULayers() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.gpuLayers = "-1"

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidNonNegativeNumericOption(name: "GPU layers", value: "-1"))
        }
    }

    func testLaunchConfigurationErrorsDescribeNextSetupStep() {
        XCTAssertEqual(
            RuntimeAdapterError.missingRuntimePath.errorDescription,
            "Choose a llama-server executable before starting."
        )
        XCTAssertEqual(
            RuntimeAdapterError.missingModelPath.errorDescription,
            "Choose a .gguf model file before starting."
        )
        XCTAssertEqual(
            RuntimeAdapterError.unsupportedModelType("/Users/kei/Models/qwen.bin").errorDescription,
            "Model file must be a .gguf file before launch. Current path: /Users/kei/Models/qwen.bin."
        )
        XCTAssertEqual(
            RuntimeAdapterError.invalidHost("bad host").errorDescription,
            "Host must be blank, localhost, an IP address, or a DNS name before endpoint copy. Current value: bad host."
        )
        XCTAssertEqual(
            RuntimeAdapterError.invalidPort(0).errorDescription,
            "Port must be between 1 and 65535 before launch. Current value: 0."
        )
        XCTAssertEqual(
            RuntimeAdapterError.invalidContextSize(0).errorDescription,
            "Context size must be greater than zero before launch. Current value: 0."
        )
        XCTAssertEqual(
            RuntimeAdapterError.invalidNumericOption(name: "threads", value: "0").errorDescription,
            "threads must be a positive integer or auto before launch. Current value: 0."
        )
        XCTAssertEqual(
            RuntimeAdapterError.invalidNonNegativeNumericOption(name: "GPU layers", value: "-1").errorDescription,
            "GPU layers must be a non-negative integer or auto before launch. Current value: -1."
        )
    }

    private func makeWorkspace() throws -> URL {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-lantern-adapter-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        return workspace
    }

    private func makeExecutableFile(at url: URL) throws {
        FileManager.default.createFile(atPath: url.path, contents: Data())
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }
}
