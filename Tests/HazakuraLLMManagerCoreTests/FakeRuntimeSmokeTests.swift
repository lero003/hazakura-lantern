import XCTest
@testable import HazakuraLLMManagerCore

final class FakeRuntimeSmokeTests: XCTestCase {
    func testLaunchCommandRunsFakeRuntimeWithoutRealModel() throws {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }

        let runtime = workspace.appendingPathComponent("fake-llama-server")
        let model = workspace.appendingPathComponent("placeholder.gguf")
        try makeFakeRuntime(at: runtime)
        FileManager.default.createFile(atPath: model.path, contents: Data())

        let config = RuntimeConfiguration(
            runtimeExecutablePath: runtime.path,
            modelPath: model.path,
            host: "127.0.0.1",
            port: 1234,
            contextSize: 4096,
            threads: "auto",
            gpuLayers: "0",
            additionalArguments: "--alias fake-runtime"
        )
        let command = try LlamaServerAdapter().buildLaunchCommand(config: config)
        let process = Process()

        process.executableURL = URL(fileURLWithPath: command.executablePath)
        process.arguments = command.arguments
        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)
    }

    private func makeWorkspace() throws -> URL {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-lantern-fake-runtime-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        return workspace
    }

    private func makeFakeRuntime(at url: URL) throws {
        let script = """
        #!/bin/sh
        model=""
        host=""
        port=""
        context=""

        while [ "$#" -gt 0 ]; do
          case "$1" in
            -m)
              model="$2"
              shift 2
              ;;
            --host)
              host="$2"
              shift 2
              ;;
            --port)
              port="$2"
              shift 2
              ;;
            -c)
              context="$2"
              shift 2
              ;;
            *)
              shift
              ;;
          esac
        done

        [ -f "$model" ] || exit 64
        [ -n "$host" ] || exit 65
        [ -n "$port" ] || exit 66
        [ -n "$context" ] || exit 67

        exit 0
        """

        try script.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }
}
