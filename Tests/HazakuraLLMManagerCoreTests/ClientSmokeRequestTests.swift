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
            curl -sS http://localhost:9876/v1/chat/completions \\
              -H 'Authorization: Bearer local' \\
              -H 'Content-Type: application/json' \\
              -d '{"messages":[{"content":"Hazakura AI Mobile runtime smoke. Reply with OK.","role":"user"}],"model":"local","stream":false}'
            """
        )
    }

    func testCurlCommandShellQuotesApostrophesInPayload() {
        let request = ClientSmokeRequest(
            baseURL: "http://localhost:9876/v1",
            userText: "Confirm owner's local runtime."
        )

        XCTAssertTrue(request.curlCommand.contains(#""content":"Confirm owner'\''s local runtime.""#))
    }
}
