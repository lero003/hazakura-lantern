import XCTest
@testable import HazakuraLLMManagerCore

final class ClientSmokeRequestTests: XCTestCase {
    func testChatCompletionsURLUsesConfiguredBaseURLWithoutDoubleSlash() {
        let request = ClientSmokeRequest(baseURL: "http://localhost:9876/v1/")

        XCTAssertEqual(request.chatCompletionsURL, "http://localhost:9876/v1/chat/completions")
    }

    func testCurlCommandBuildsOpenAICompatibleNonStreamingChatRequest() {
        let request = ClientSmokeRequest(baseURL: "http://localhost:9876/v1")

        XCTAssertEqual(
            request.curlCommand,
            """
            curl -fsS --max-time 60 http://localhost:9876/v1/chat/completions \\
              -H 'Authorization: Bearer local' \\
              -H 'Content-Type: application/json' \\
              -d '{"messages":[{"content":"Hazakura AI Mobile runtime smoke. Reply with OK.","role":"user"}],"model":"local","stream":false}'
            """
        )
    }

    func testCurlCommandAllowsCustomPositiveTimeout() {
        let request = ClientSmokeRequest(baseURL: "http://localhost:9876/v1", timeoutSeconds: 10)

        XCTAssertTrue(request.curlCommand.hasPrefix("curl -fsS --max-time 10 "))
    }

    func testCurlCommandKeepsTimeoutPositive() {
        let request = ClientSmokeRequest(baseURL: "http://localhost:9876/v1", timeoutSeconds: 0)

        XCTAssertTrue(request.curlCommand.hasPrefix("curl -fsS --max-time 1 "))
    }

    func testCurlCommandShellQuotesApostrophesInPayload() {
        let request = ClientSmokeRequest(
            baseURL: "http://localhost:9876/v1",
            userText: "Confirm owner's local runtime."
        )

        XCTAssertTrue(request.curlCommand.contains(#""content":"Confirm owner'\''s local runtime.""#))
    }
}
