import XCTest
@testable import HazakuraLLMManagerCore

final class RuntimeProfileDocumentTests: XCTestCase {
    func testProfileDocumentPinsSchemaVersionAndRuntimeKind() throws {
        let configuration = RuntimeConfiguration(
            runtimeExecutablePath: "/opt/llama.cpp/llama-server",
            modelPath: "/models/hazakura.gguf",
            host: "127.0.0.1",
            port: 4321,
            contextSize: 8192,
            threads: "6",
            gpuLayers: "0",
            additionalArguments: "--verbose"
        )
        let document = RuntimeProfileDocument(
            name: "Desk runtime",
            configuration: configuration
        )

        let data = try JSONEncoder().encode(document)
        let decoded = try JSONDecoder().decode(RuntimeProfileDocument.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.runtimeKind, "llama-server")
        XCTAssertEqual(decoded, document)
    }

    func testProfileDocumentExportsStableReadableJSON() throws {
        let document = RuntimeProfileDocument(
            name: "Desk runtime",
            configuration: RuntimeConfiguration(
                runtimeExecutablePath: "/opt/llama.cpp/llama-server",
                modelPath: "/models/hazakura.gguf",
                host: "127.0.0.1",
                port: 4321,
                contextSize: 8192,
                threads: "6",
                gpuLayers: "0",
                additionalArguments: "--verbose"
            )
        )

        let data = try document.exportJSONData()
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(json.contains("\n  \"configuration\" : {"))
        XCTAssertTrue(json.contains("\"schemaVersion\" : 1"))
        XCTAssertTrue(json.contains("/opt/llama.cpp/llama-server"))
        XCTAssertFalse(json.contains("\\/opt\\/llama.cpp\\/llama-server"))
        XCTAssertEqual(try RuntimeProfileDocument.importJSONData(data), document)
    }

    func testProfileDocumentSuggestsStableExportFileName() {
        let document = RuntimeProfileDocument(
            name: "Desk runtime",
            configuration: .defaultValue
        )

        XCTAssertEqual(document.suggestedExportFileName, "Desk-runtime.lantern-profile.json")
        XCTAssertEqual(
            RuntimeProfileDocument.suggestedExportFileName(for: " GPU 0 / Desk: Local "),
            "GPU-0-Desk-Local.lantern-profile.json"
        )
        XCTAssertEqual(
            RuntimeProfileDocument.suggestedExportFileName(for: "Desk-runtime.lantern-profile.json"),
            "Desk-runtime.lantern-profile.json"
        )
        XCTAssertEqual(
            RuntimeProfileDocument.suggestedExportFileName(for: " \n "),
            "Runtime-Profile.lantern-profile.json"
        )
    }

    func testProfileDocumentRecognizesSupportedProfileFileNames() {
        XCTAssertTrue(
            RuntimeProfileDocument.isSupportedProfileFileName("Desk-runtime.lantern-profile.json")
        )
        XCTAssertTrue(
            RuntimeProfileDocument.isSupportedProfileFileName(" Desk-runtime.LANTERN-PROFILE.JSON\n")
        )
        XCTAssertFalse(
            RuntimeProfileDocument.isSupportedProfileFileName("Desk-runtime.json")
        )
        XCTAssertFalse(
            RuntimeProfileDocument.isSupportedProfileFileName("Desk-runtime.lantern-profile.json.backup")
        )
    }

    func testProfileDocumentRecognizesSupportedProfileFileURLs() {
        XCTAssertTrue(
            RuntimeProfileDocument.isSupportedProfileFileURL(
                URL(fileURLWithPath: "/tmp/Desk runtime.lantern-profile.json")
            )
        )
        XCTAssertFalse(
            RuntimeProfileDocument.isSupportedProfileFileURL(
                URL(fileURLWithPath: "/tmp/Desk runtime.json")
            )
        )
    }

    func testProfileDocumentImportsFromSupportedProfileFileName() throws {
        let document = RuntimeProfileDocument(
            name: "Desk runtime",
            configuration: .defaultValue
        )
        let data = try document.exportJSONData()

        XCTAssertEqual(
            try RuntimeProfileDocument.importJSONData(
                data,
                fromProfileFileNamed: " Desk-runtime.LANTERN-PROFILE.JSON\n"
            ),
            document
        )
        XCTAssertEqual(
            try RuntimeProfileDocument.importJSONData(
                data,
                fromProfileFileURL: URL(fileURLWithPath: "/tmp/Desk-runtime.lantern-profile.json")
            ),
            document
        )
    }

    func testProfileDocumentPreviewsSupportedProfileFileWithoutFullImport() throws {
        let json = """
        {
          "schemaVersion": 1,
          "name": "Desk runtime",
          "runtimeKind": "llama-server"
        }
        """

        XCTAssertEqual(
            try RuntimeProfileDocument.previewJSONData(
                Data(json.utf8),
                fromProfileFileNamed: "Desk-runtime.lantern-profile.json"
            ),
            RuntimeProfileDocument.ImportPreview(
                schemaVersion: 1,
                name: "Desk runtime",
                runtimeKind: "llama-server"
            )
        )
        XCTAssertEqual(
            try RuntimeProfileDocument.previewJSONData(
                Data(json.utf8),
                fromProfileFileURL: URL(fileURLWithPath: "/tmp/Desk-runtime.lantern-profile.json")
            ),
            RuntimeProfileDocument.ImportPreview(
                schemaVersion: 1,
                name: "Desk runtime",
                runtimeKind: "llama-server"
            )
        )
    }

    func testProfileDocumentRejectsUnsupportedProfileFileNameBeforeImport() {
        let data = Data("not profile json".utf8)

        XCTAssertThrowsError(
            try RuntimeProfileDocument.importJSONData(
                data,
                fromProfileFileNamed: "Desk-runtime.json"
            )
        ) { error in
            XCTAssertEqual(
                error as? RuntimeProfileDocument.ImportError,
                .unsupportedFileName("Desk-runtime.json", expectedSuffix: ".lantern-profile.json")
            )
            XCTAssertEqual(
                error.localizedDescription,
                "Runtime profile file \"Desk-runtime.json\" is not supported; expected a .lantern-profile.json file."
            )
        }
    }

    func testProfileDocumentRejectsUnsupportedProfileFileNameBeforePreview() {
        let data = Data("not profile json".utf8)

        XCTAssertThrowsError(
            try RuntimeProfileDocument.previewJSONData(
                data,
                fromProfileFileNamed: "Desk-runtime.json"
            )
        ) { error in
            XCTAssertEqual(
                error as? RuntimeProfileDocument.ImportError,
                .unsupportedFileName("Desk-runtime.json", expectedSuffix: ".lantern-profile.json")
            )
        }
    }

    func testProfileDocumentListsLocalFileReferencesForPortabilityWarnings() {
        let document = RuntimeProfileDocument(
            name: "Desk runtime",
            configuration: RuntimeConfiguration(
                runtimeExecutablePath: " /opt/llama.cpp/llama-server ",
                modelPath: "/models/hazakura.gguf\n",
                host: "127.0.0.1",
                port: 4321,
                contextSize: 8192,
                threads: "6",
                gpuLayers: "0",
                additionalArguments: "--verbose"
            )
        )

        XCTAssertEqual(
            document.localFileReferences,
            [
                .init(role: .runtimeExecutable, path: "/opt/llama.cpp/llama-server"),
                .init(role: .modelFile, path: "/models/hazakura.gguf")
            ]
        )
        XCTAssertEqual(
            document.localFileReferences.map(\.role.displayName),
            ["Runtime executable", "Model file"]
        )
    }

    func testProfileDocumentOmitsEmptyLocalFileReferences() {
        let document = RuntimeProfileDocument(
            name: "Incomplete runtime",
            configuration: RuntimeConfiguration(
                runtimeExecutablePath: "  ",
                modelPath: "\n",
                host: "127.0.0.1",
                port: 1234,
                contextSize: 4096,
                threads: "auto",
                gpuLayers: "auto",
                additionalArguments: ""
            )
        )

        XCTAssertEqual(document.localFileReferences, [])
    }

    func testProfileDocumentBuildsLaunchCommandWithMatchingAdapter() throws {
        let document = RuntimeProfileDocument(
            name: "Desk runtime",
            configuration: RuntimeConfiguration(
                runtimeExecutablePath: "/opt/llama.cpp/llama-server",
                modelPath: "/models/hazakura.gguf",
                host: "127.0.0.1",
                port: 4321,
                contextSize: 8192,
                threads: "6",
                gpuLayers: "0",
                additionalArguments: "--alias \"desk runtime\""
            )
        )

        let command = try document.launchCommand(using: LlamaServerAdapter())

        XCTAssertEqual(command.executablePath, "/opt/llama.cpp/llama-server")
        XCTAssertEqual(command.arguments, [
            "-m", "/models/hazakura.gguf",
            "--host", "127.0.0.1",
            "--port", "4321",
            "-c", "8192",
            "-t", "6",
            "-ngl", "0",
            "--alias", "desk runtime"
        ])
        XCTAssertEqual(
            command.displayString,
            "/opt/llama.cpp/llama-server -m /models/hazakura.gguf --host 127.0.0.1 --port 4321 -c 8192 -t 6 -ngl 0 --alias 'desk runtime'"
        )
    }

    func testProfileDocumentRejectsLaunchCommandPreviewWithMismatchedAdapter() {
        let document = RuntimeProfileDocument(
            name: "Other runtime",
            runtimeKind: "custom-command",
            configuration: .defaultValue
        )

        XCTAssertThrowsError(try document.launchCommand(using: LlamaServerAdapter())) { error in
            XCTAssertEqual(
                error as? RuntimeProfileDocument.LaunchCommandError,
                .adapterMismatch(profileRuntimeKind: "custom-command", adapterID: "llama-server")
            )
            XCTAssertEqual(
                error.localizedDescription,
                "Runtime profile kind \"custom-command\" cannot be previewed with adapter \"llama-server\"."
            )
        }
    }

    func testProfileDocumentImportRejectsUnsupportedSchemaVersionWithTypedError() {
        let json = """
        {
          "schemaVersion": 2,
          "name": "Future runtime",
          "runtimeKind": "llama-server",
          "configuration": {
            "runtimeExecutablePath": "/opt/llama.cpp/llama-server",
            "modelPath": "/models/hazakura.gguf",
            "host": "127.0.0.1",
            "port": 1234,
            "contextSize": 4096,
            "threads": "auto",
            "gpuLayers": "auto",
            "additionalArguments": ""
          }
        }
        """

        XCTAssertThrowsError(
            try RuntimeProfileDocument.importJSONData(Data(json.utf8))
        ) { error in
            XCTAssertEqual(
                error as? RuntimeProfileDocument.ImportError,
                .unsupportedSchemaVersion(2, supportedVersion: 1)
            )
            XCTAssertEqual(
                error.localizedDescription,
                "Runtime profile schema version 2 is not supported by this Lantern build; supported version is 1."
            )
        }
    }

    func testProfileDocumentImportRejectsMissingSchemaVersionWithTypedError() {
        let json = """
        {
          "name": "Schema-less runtime",
          "runtimeKind": "llama-server",
          "configuration": {
            "runtimeExecutablePath": "/opt/llama.cpp/llama-server",
            "modelPath": "/models/hazakura.gguf",
            "host": "127.0.0.1",
            "port": 1234,
            "contextSize": 4096,
            "threads": "auto",
            "gpuLayers": "auto",
            "additionalArguments": ""
          }
        }
        """

        XCTAssertThrowsError(
            try RuntimeProfileDocument.importJSONData(Data(json.utf8))
        ) { error in
            XCTAssertEqual(error as? RuntimeProfileDocument.ImportError, .missingSchemaVersion)
            XCTAssertEqual(error.localizedDescription, "Runtime profile is missing schemaVersion.")
        }
    }

    func testProfileDocumentImportRejectsMissingRuntimeKindWithTypedError() {
        let json = """
        {
          "schemaVersion": 1,
          "name": "Kind-less runtime",
          "configuration": {
            "runtimeExecutablePath": "/opt/llama.cpp/llama-server",
            "modelPath": "/models/hazakura.gguf",
            "host": "127.0.0.1",
            "port": 1234,
            "contextSize": 4096,
            "threads": "auto",
            "gpuLayers": "auto",
            "additionalArguments": ""
          }
        }
        """

        XCTAssertThrowsError(
            try RuntimeProfileDocument.importJSONData(Data(json.utf8))
        ) { error in
            XCTAssertEqual(error as? RuntimeProfileDocument.ImportError, .missingRuntimeKind)
            XCTAssertEqual(error.localizedDescription, "Runtime profile is missing runtimeKind.")
        }
    }

    func testProfileDocumentImportRejectsMissingNameWithTypedError() {
        let json = """
        {
          "schemaVersion": 1,
          "runtimeKind": "llama-server",
          "configuration": {
            "runtimeExecutablePath": "/opt/llama.cpp/llama-server",
            "modelPath": "/models/hazakura.gguf",
            "host": "127.0.0.1",
            "port": 1234,
            "contextSize": 4096,
            "threads": "auto",
            "gpuLayers": "auto",
            "additionalArguments": ""
          }
        }
        """

        XCTAssertThrowsError(
            try RuntimeProfileDocument.importJSONData(Data(json.utf8))
        ) { error in
            XCTAssertEqual(error as? RuntimeProfileDocument.ImportError, .missingName)
            XCTAssertEqual(error.localizedDescription, "Runtime profile is missing name.")
        }
    }

    func testProfileDocumentImportRejectsUnsupportedRuntimeKindWithTypedError() {
        let json = """
        {
          "schemaVersion": 1,
          "name": "Other runtime",
          "runtimeKind": "ollama",
          "configuration": {
            "runtimeExecutablePath": "/opt/ollama",
            "modelPath": "/models/hazakura.gguf",
            "host": "127.0.0.1",
            "port": 1234,
            "contextSize": 4096,
            "threads": "auto",
            "gpuLayers": "auto",
            "additionalArguments": ""
          }
        }
        """

        XCTAssertThrowsError(
            try RuntimeProfileDocument.importJSONData(Data(json.utf8))
        ) { error in
            XCTAssertEqual(
                error as? RuntimeProfileDocument.ImportError,
                .unsupportedRuntimeKind("ollama", supportedRuntimeKind: "llama-server")
            )
            XCTAssertEqual(
                error.localizedDescription,
                "Runtime profile runtime kind \"ollama\" is not supported by this Lantern build; supported kind is llama-server."
            )
        }
    }

    func testProfileDocumentRejectsUnsupportedSchemaVersion() {
        let json = """
        {
          "schemaVersion": 2,
          "name": "Future runtime",
          "runtimeKind": "llama-server",
          "configuration": {
            "runtimeExecutablePath": "/opt/llama.cpp/llama-server",
            "modelPath": "/models/hazakura.gguf",
            "host": "127.0.0.1",
            "port": 1234,
            "contextSize": 4096,
            "threads": "auto",
            "gpuLayers": "auto",
            "additionalArguments": ""
          }
        }
        """

        XCTAssertThrowsError(
            try JSONDecoder().decode(RuntimeProfileDocument.self, from: Data(json.utf8))
        ) { error in
            XCTAssertTrue(String(describing: error).contains("Unsupported runtime profile schema version 2"))
        }
    }

    func testProfileDocumentRejectsUnsupportedRuntimeKind() {
        let json = """
        {
          "schemaVersion": 1,
          "name": "Other runtime",
          "runtimeKind": "ollama",
          "configuration": {
            "runtimeExecutablePath": "/opt/ollama",
            "modelPath": "/models/hazakura.gguf",
            "host": "127.0.0.1",
            "port": 1234,
            "contextSize": 4096,
            "threads": "auto",
            "gpuLayers": "auto",
            "additionalArguments": ""
          }
        }
        """

        XCTAssertThrowsError(
            try JSONDecoder().decode(RuntimeProfileDocument.self, from: Data(json.utf8))
        ) { error in
            XCTAssertEqual(
                error as? RuntimeProfileDocument.ImportError,
                .unsupportedRuntimeKind("ollama", supportedRuntimeKind: "llama-server")
            )
        }
    }
}
