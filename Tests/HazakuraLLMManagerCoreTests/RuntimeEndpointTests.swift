import XCTest
@testable import HazakuraLLMManagerCore

final class RuntimeEndpointTests: XCTestCase {
    func testEnvironmentSnippetKeepsDefaultLocalValuesReadable() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1")),
            healthCheckURL: nil
        )

        XCTAssertEqual(
            endpoint.environmentSnippet,
            """
            OPENAI_BASE_URL=http://localhost:1234/v1
            OPENAI_MODEL_ID=local
            """
        )
    }

    func testEnvironmentSnippetShellQuotesAdapterScopedValues() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1?profile=owner-desk")),
            healthCheckURL: nil,
            modelID: "owner's model",
            apiKey: "owner's local key"
        )

        XCTAssertEqual(
            endpoint.environmentSnippet,
            """
            OPENAI_BASE_URL='http://localhost:1234/v1?profile=owner-desk'
            OPENAI_MODEL_ID='owner'\\''s model'
            OPENAI_API_KEY='owner'\\''s local key'
            """
        )
    }

    func testOpenCodeConfigSnippetUsesLocalOpenAICompatibleProvider() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:9876/v1")),
            healthCheckURL: nil,
            modelID: "qwen",
            modelName: "qwen.gguf"
        )

        XCTAssertEqual(
            endpoint.openCodeConfigSnippet,
            """
            {
              "$schema" : "https://opencode.ai/config.json",
              "model" : "lantern/qwen",
              "provider" : {
                "lantern" : {
                  "models" : {
                    "qwen" : {
                      "name" : "qwen.gguf"
                    }
                  },
                  "name" : "Hazakura Lantern (local)",
                  "npm" : "@ai-sdk/openai-compatible",
                  "options" : {
                    "baseURL" : "http://localhost:9876/v1"
                  }
                }
              }
            }
            """
        )
    }

    func testHazakuraNoteConnectionSnippetKeepsConnectionFactsSmall() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:9876/v1")),
            healthCheckURL: nil,
            modelID: "qwen",
            modelName: "qwen.gguf"
        )

        XCTAssertEqual(
            endpoint.hazakuraNoteConnectionSnippet,
            """
            {
              "apiKeyRequired" : false,
              "baseURL" : "http://localhost:9876/v1",
              "model" : "qwen",
              "modelName" : "qwen.gguf",
              "provider" : "openai-compatible",
              "schemaVersion" : 1
            }
            """
        )
    }

    func testConnectionSnapshotSnippetIncludesHealthURLWhenAvailable() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:9876/v1")),
            healthCheckURL: try XCTUnwrap(URL(string: "http://localhost:9876/v1/models")),
            modelID: "qwen",
            modelName: "qwen.gguf"
        )

        XCTAssertEqual(
            endpoint.connectionSnapshotSnippet,
            """
            {
              "api" : "openai-compatible",
              "apiKeyRequired" : false,
              "baseURL" : "http://localhost:9876/v1",
              "healthCheckURL" : "http://localhost:9876/v1/models",
              "modelID" : "qwen",
              "modelName" : "qwen.gguf",
              "schemaVersion" : 1,
              "source" : "hazakura-lantern"
            }
            """
        )
    }

    func testEndpointHealthRequestUsesAdapterScopedTimeout() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1")),
            healthCheckURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1/models")),
            healthCheckTimeoutSeconds: 2
        )

        XCTAssertEqual(
            endpoint.endpointHealthCurlCommand,
            "curl -fsS --max-time 2 http://localhost:1234/v1/models"
        )
    }

    func testEndpointHealthRequestKeepsDefaultTimeout() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1")),
            healthCheckURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1/models"))
        )

        XCTAssertEqual(
            endpoint.endpointHealthCurlCommand,
            "curl -fsS --max-time 5 http://localhost:1234/v1/models"
        )
    }
}
