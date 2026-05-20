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
              --spec-type=TYPE
              --spec-draft-n-max N
            """
        )

        XCTAssertEqual(capabilities.versionSummary, "llama-server version b4600")
        XCTAssertTrue(capabilities.supports(option: "--model"))
        XCTAssertTrue(capabilities.supports(option: "--ctx-size"))
        XCTAssertTrue(capabilities.supports(option: "--cache-type-k"))
        XCTAssertTrue(capabilities.supports(option: "--spec-type"))
        XCTAssertTrue(capabilities.supports(option: "--spec-draft-n-max"))
    }

    func testUnsupportedPresetOptionsStayVisibleForWarnings() {
        let capabilities = LlamaServerRuntimeCapabilities.parse(
            versionOutput: nil,
            helpOutput: """
              --model FNAME
              --ctx-size N
              --spec-type TYPE
            """
        )

        XCTAssertEqual(
            capabilities.unsupportedOptions(for: .mtpCapable),
            ["--spec-draft-n-max"]
        )
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
        XCTAssertTrue(result.capabilities.supports(option: "--spec-type"))
        XCTAssertTrue(result.capabilities.supports(option: "--spec-draft-n-max"))
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
            printf '%s\\n' '--spec-type TYPE'
            printf '%s\\n' '--spec-draft-n-max N'
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
