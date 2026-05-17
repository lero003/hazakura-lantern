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
