import XCTest
@testable import HazakuraLLMManagerCore

final class ClientSmokeRequestTests: XCTestCase {
    func testDefaultUserTextIsTheBoundedLocalSmokePrompt() {
        let request = ClientSmokeRequest(baseURL: "http://localhost:9876/v1")

        XCTAssertEqual(
            request.userText,
            "Hazakura AI Mobile runtime smoke. Reply with OK."
        )
        XCTAssertTrue(request.curlCommand.contains(#""content":"\#(ClientSmokeRequest.defaultUserText)""#))
    }

    func testChatCompletionsURLUsesConfiguredBaseURLWithoutDoubleSlash() {
        let request = ClientSmokeRequest(baseURL: "http://localhost:9876/v1/")

        XCTAssertEqual(request.chatCompletionsURL, "http://localhost:9876/v1/chat/completions")
    }

    func testCurlCommandBuildsOpenAICompatibleNonStreamingChatRequest() {
        let request = ClientSmokeRequest(baseURL: "http://localhost:9876/v1")

        XCTAssertEqual(
            request.curlCommand,
            """
            curl -fsS --max-time 180 http://localhost:9876/v1/chat/completions \\
              -H 'Content-Type: application/json' \\
              -d '{"max_tokens":2048,"messages":[{"content":"Hazakura AI Mobile runtime smoke. Reply with OK.","role":"user"}],"model":"local","stream":false}'
            """
        )
    }

    func testCurlCommandAddsAuthorizationOnlyWhenAPIKeyIsConfigured() {
        let request = ClientSmokeRequest(
            baseURL: "http://localhost:9876/v1",
            apiKey: "owner local key"
        )

        XCTAssertTrue(request.curlCommand.contains("-H 'Authorization: Bearer owner local key'"))
    }

    func testCurlCommandAllowsCustomPositiveTimeout() {
        let request = ClientSmokeRequest(baseURL: "http://localhost:9876/v1", timeoutSeconds: 10)

        XCTAssertTrue(request.curlCommand.hasPrefix("curl -fsS --max-time 10 "))
    }

    func testCurlCommandKeepsTimeoutPositive() {
        let request = ClientSmokeRequest(baseURL: "http://localhost:9876/v1", timeoutSeconds: 0)

        XCTAssertTrue(request.curlCommand.hasPrefix("curl -fsS --max-time 1 "))
    }

    func testCurlCommandKeepsMaxTokensPositive() {
        let request = ClientSmokeRequest(baseURL: "http://localhost:9876/v1", maxTokens: 0)

        XCTAssertTrue(request.curlCommand.contains(#""max_tokens":1"#))
    }

    func testCurlCommandShellQuotesApostrophesInPayload() {
        let request = ClientSmokeRequest(
            baseURL: "http://localhost:9876/v1",
            userText: "Confirm owner's local runtime."
        )

        XCTAssertTrue(request.curlCommand.contains(#""content":"Confirm owner'\''s local runtime.""#))
    }
}
