import Foundation

public struct LlamaServerInstallSourceAdvice: Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        case homebrew
        case macPorts
        case sourceCheckout
        case manualPath
    }

    public let source: Source
    public let title: String
    public let detail: String

    public init(source: Source, title: String, detail: String) {
        self.source = source
        self.title = title
        self.detail = detail
    }

    public static func classify(executablePath rawPath: String) -> LlamaServerInstallSourceAdvice? {
        let path = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            return nil
        }

        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let lowercasedPath = standardizedPath.lowercased()

        if isHomebrewPath(lowercasedPath) {
            return LlamaServerInstallSourceAdvice(
                source: .homebrew,
                title: "Runtime source: Homebrew-style path",
                detail: "Lantern can check version and option support, but runtime updates stay outside the app."
            )
        }

        if lowercasedPath.hasPrefix("/opt/local/") {
            return LlamaServerInstallSourceAdvice(
                source: .macPorts,
                title: "Runtime source: MacPorts-style path",
                detail: "Lantern treats this as a local runtime and will not run package-manager updates."
            )
        }

        if isSourceCheckoutPath(lowercasedPath) {
            return LlamaServerInstallSourceAdvice(
                source: .sourceCheckout,
                title: "Runtime source: source checkout path",
                detail: "Lantern can inspect this binary, but rebuilding or updating the checkout stays manual."
            )
        }

        return LlamaServerInstallSourceAdvice(
            source: .manualPath,
            title: "Runtime source: manual path",
            detail: "Lantern cannot infer an install manager from this path; keep updates manual and visible."
        )
    }

    private static func isHomebrewPath(_ path: String) -> Bool {
        path.hasPrefix("/opt/homebrew/")
            || path.hasPrefix("/usr/local/cellar/")
            || path.hasPrefix("/usr/local/homebrew/")
            || path.hasPrefix("/usr/local/opt/")
    }

    private static func isSourceCheckoutPath(_ path: String) -> Bool {
        path.contains("/llama.cpp/")
            || path.contains("/llama-cpp/")
            || path.contains("/llamacpp/")
    }
}
