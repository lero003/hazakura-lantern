import XCTest
@testable import HazakuraLLMManagerCore

final class LlamaServerRuntimeDiscoveryTests: XCTestCase {
    func testCandidateExecutablePathsIncludePathAndDefaultPackageManagerLocations() {
        let discovery = LlamaServerRuntimeDiscovery()

        let paths = discovery.candidateExecutablePaths(
            environmentPath: "/custom/bin:/opt/homebrew/bin:relative/bin",
            additionalSearchDirectories: ["/usr/local/bin", "/custom/bin"]
        )

        XCTAssertEqual(
            paths,
            [
                "/custom/bin/llama-server",
                "/opt/homebrew/bin/llama-server",
                "/usr/local/bin/llama-server"
            ]
        )
    }

    func testInstalledExecutablePathsOnlyReturnExecutableCandidates() throws {
        let workspace = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }

        let executableDirectory = workspace.appendingPathComponent("bin")
        let nonExecutableDirectory = workspace.appendingPathComponent("not-executable")
        let directoryCandidateParent = workspace.appendingPathComponent("directory-candidate")
        try FileManager.default.createDirectory(at: executableDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: nonExecutableDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: directoryCandidateParent, withIntermediateDirectories: true)

        let executable = executableDirectory.appendingPathComponent("llama-server")
        let nonExecutable = nonExecutableDirectory.appendingPathComponent("llama-server")
        let directoryCandidate = directoryCandidateParent.appendingPathComponent("llama-server")
        try makeFile(at: executable, executable: true)
        try makeFile(at: nonExecutable, executable: false)
        try FileManager.default.createDirectory(at: directoryCandidate, withIntermediateDirectories: false)

        let discovery = LlamaServerRuntimeDiscovery()

        XCTAssertEqual(
            discovery.installedExecutablePaths(
                environmentPath: "\(executableDirectory.path):\(nonExecutableDirectory.path):\(directoryCandidateParent.path)",
                additionalSearchDirectories: []
            ),
            [executable.path]
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LlamaServerRuntimeDiscoveryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeFile(at url: URL, executable: Bool) throws {
        _ = FileManager.default.createFile(atPath: url.path, contents: Data("#!/bin/sh\n".utf8))
        try FileManager.default.setAttributes(
            [.posixPermissions: executable ? 0o755 : 0o644],
            ofItemAtPath: url.path
        )
    }
}
