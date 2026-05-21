import XCTest
@testable import HazakuraLLMManagerCore

final class LlamaServerCapabilityProbeTests: XCTestCase {
    func testParseKeepsVersionSummaryAndSupportedOptions() {
        let capabilities = LlamaServerRuntimeCapabilities.parse(
            versionOutput: """
            llama-server version b4600
            built with Apple clang
            """,
            helpOutput: """
              -m, --model FNAME
              --ctx-size N
              --cache-type-k TYPE
              --cache-type-v TYPE
              --flash-attn [on|off|auto]
            """
        )

        XCTAssertEqual(capabilities.versionSummary, "llama-server version b4600")
        XCTAssertTrue(capabilities.supports(option: "--model"))
        XCTAssertTrue(capabilities.supports(option: "--ctx-size"))
        XCTAssertTrue(capabilities.supports(option: "--cache-type-k"))
        XCTAssertTrue(capabilities.supports(option: "--cache-type-v"))
        XCTAssertTrue(capabilities.supports(option: "--flash-attn"))
    }

    func testUnsupportedPresetOptionsStayVisibleForWarnings() {
        let capabilities = LlamaServerRuntimeCapabilities.parse(
            versionOutput: nil,
            helpOutput: """
              --model FNAME
              --ctx-size N
              --flash-attn [on|off|auto]
              --cache-type-k TYPE
            """
        )

        XCTAssertEqual(
            capabilities.unsupportedOptions(for: .qwenRecommended),
            ["--cache-type-v"]
        )
    }

    func testPresetCompatibilityNoteReportsSupportedOptions() {
        let result = LlamaServerCapabilityProbeResult(
            versionCheck: .init(
                output: "llama-server fake b1",
                terminationStatus: 0,
                didTimeOut: false,
                errorDescription: nil
            ),
            helpCheck: .init(
                output: "--flash-attn [on|off|auto]\n--cache-type-k TYPE\n--cache-type-v TYPE",
                terminationStatus: 0,
                didTimeOut: false,
                errorDescription: nil
            ),
            capabilities: .parse(
                versionOutput: "llama-server fake b1",
                helpOutput: "--flash-attn [on|off|auto]\n--cache-type-k TYPE\n--cache-type-v TYPE"
            )
        )

        let note = result.presetCompatibilityNote(for: .qwenRecommended)

        XCTAssertEqual(note.severity, .supported)
        XCTAssertEqual(note.title, "Preset options are listed by this runtime")
    }

    func testPresetCompatibilityNoteWarnsAboutMissingOptions() {
        let result = LlamaServerCapabilityProbeResult(
            versionCheck: .init(
                output: "",
                terminationStatus: 0,
                didTimeOut: false,
                errorDescription: nil
            ),
            helpCheck: .init(
                output: "--flash-attn [on|off|auto]\n--cache-type-k TYPE",
                terminationStatus: 0,
                didTimeOut: false,
                errorDescription: nil
            ),
            capabilities: .parse(
                versionOutput: nil,
                helpOutput: "--flash-attn [on|off|auto]\n--cache-type-k TYPE"
            )
        )

        let note = result.presetCompatibilityNote(for: .qwenRecommended)

        XCTAssertEqual(note.severity, .warning)
        XCTAssertTrue(note.detail.contains("--cache-type-v"))
    }

    func testPresetCompatibilityNoteKeepsTimeoutUnknown() {
        let result = LlamaServerCapabilityProbeResult(
            versionCheck: .init(
                output: "",
                terminationStatus: nil,
                didTimeOut: true,
                errorDescription: nil
            ),
            helpCheck: .init(
                output: "",
                terminationStatus: nil,
                didTimeOut: true,
                errorDescription: nil
            ),
            capabilities: .parse(versionOutput: nil, helpOutput: nil)
        )

        let note = result.presetCompatibilityNote(for: .qwenRecommended)

        XCTAssertEqual(note.severity, .unknown)
        XCTAssertTrue(note.detail.contains("--help check did not finish"))
    }

    func testProbeRunsVersionAndHelpWithoutModelArguments() throws {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }

        let runtime = workspace.appendingPathComponent("fake-llama-server")
        try makeFakeRuntime(at: runtime)

        let result = LlamaServerCapabilityProbe(timeout: 1).probe(executablePath: runtime.path)

        XCTAssertFalse(result.versionCheck.didTimeOut)
        XCTAssertFalse(result.helpCheck.didTimeOut)
        XCTAssertEqual(result.versionCheck.terminationStatus, 0)
        XCTAssertEqual(result.helpCheck.terminationStatus, 0)
        XCTAssertEqual(result.capabilities.versionSummary, "llama-server fake b1")
        XCTAssertTrue(result.capabilities.supports(option: "--flash-attn"))
        XCTAssertTrue(result.capabilities.supports(option: "--cache-type-k"))
        XCTAssertTrue(result.capabilities.supports(option: "--cache-type-v"))
    }

    func testProbeTimesOutReadOnlyChecks() throws {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }

        let runtime = workspace.appendingPathComponent("slow-llama-server")
        try makeSlowRuntime(at: runtime)

        let result = LlamaServerCapabilityProbe(timeout: 0.1).probe(executablePath: runtime.path)

        XCTAssertTrue(result.versionCheck.didTimeOut)
        XCTAssertTrue(result.helpCheck.didTimeOut)
    }

    private func makeWorkspace() throws -> URL {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-lantern-capability-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        return workspace
    }

    private func makeFakeRuntime(at url: URL) throws {
        let script = """
        #!/bin/sh
        case "$1" in
          --version)
            printf '%s\\n' 'llama-server fake b1'
            ;;
          --help)
            printf '%s\\n' '--model FNAME'
            printf '%s\\n' '--ctx-size N'
            printf '%s\\n' '--flash-attn [on|off|auto]'
            printf '%s\\n' '--cache-type-k TYPE'
            printf '%s\\n' '--cache-type-v TYPE'
            ;;
          *)
            exit 64
            ;;
        esac
        """

        try script.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    private func makeSlowRuntime(at url: URL) throws {
        let script = """
        #!/bin/sh
        trap '' TERM
        while :; do
          :
        done
        """

        try script.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }
}
