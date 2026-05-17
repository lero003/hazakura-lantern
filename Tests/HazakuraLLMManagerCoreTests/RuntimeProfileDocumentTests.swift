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
}
