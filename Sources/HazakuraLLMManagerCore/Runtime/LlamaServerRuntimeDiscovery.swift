import Foundation

public struct LlamaServerRuntimeDiscovery: Sendable {
    public static let executableName = "llama-server"

    public static let defaultSearchDirectories = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/opt/local/bin"
    ]

    public init() {}

    public func candidateExecutablePaths(
        environmentPath: String? = ProcessInfo.processInfo.environment["PATH"],
        additionalSearchDirectories: [String] = Self.defaultSearchDirectories
    ) -> [String] {
        var seen = Set<String>()
        var paths: [String] = []

        for directory in searchDirectories(
            environmentPath: environmentPath,
            additionalSearchDirectories: additionalSearchDirectories
        ) {
            let path = URL(fileURLWithPath: directory)
                .appendingPathComponent(Self.executableName)
                .path

            if seen.insert(path).inserted {
                paths.append(path)
            }
        }

        return paths
    }

    public func installedExecutablePaths(
        fileManager: FileManager = .default,
        environmentPath: String? = ProcessInfo.processInfo.environment["PATH"],
        additionalSearchDirectories: [String] = Self.defaultSearchDirectories
    ) -> [String] {
        candidateExecutablePaths(
            environmentPath: environmentPath,
            additionalSearchDirectories: additionalSearchDirectories
        )
        .filter { path in
            var isDirectory: ObjCBool = false
            return fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
                && !isDirectory.boolValue
                && fileManager.isExecutableFile(atPath: path)
        }
    }

    private func searchDirectories(
        environmentPath: String?,
        additionalSearchDirectories: [String]
    ) -> [String] {
        let pathDirectories = environmentPath?
            .split(separator: ":", omittingEmptySubsequences: true)
            .map(String.init) ?? []

        return (pathDirectories + additionalSearchDirectories)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.hasPrefix("/") }
    }
}
