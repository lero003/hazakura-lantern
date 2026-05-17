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
