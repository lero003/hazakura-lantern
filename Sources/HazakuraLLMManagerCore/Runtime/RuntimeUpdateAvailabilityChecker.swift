import Foundation

public enum RuntimeUpdateCheckTarget: String, CaseIterable, Identifiable, Sendable {
    case llamaCpp

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .llamaCpp:
            "llama.cpp"
        }
    }

    var latestReleaseURL: URL {
        switch self {
        case .llamaCpp:
            URL(string: "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest")!
        }
    }
}

public struct RuntimeLatestRelease: Equatable, Sendable {
    public let tagName: String
    public let htmlURL: URL?
    public let publishedAt: Date?

    public init(tagName: String, htmlURL: URL?, publishedAt: Date?) {
        self.tagName = tagName
        self.htmlURL = htmlURL
        self.publishedAt = publishedAt
    }
}

public struct RuntimeUpdateAvailability: Equatable, Sendable {
    public enum Comparison: Equatable, Sendable {
        case updateAvailable
        case currentOrNewer
        case unknownLocalVersion
        case unknownLatestVersion
    }

    public let target: RuntimeUpdateCheckTarget
    public let latestRelease: RuntimeLatestRelease
    public let localVersionSummary: String?
    public let comparison: Comparison

    public init(
        target: RuntimeUpdateCheckTarget,
        latestRelease: RuntimeLatestRelease,
        localVersionSummary: String?,
        comparison: Comparison
    ) {
        self.target = target
        self.latestRelease = latestRelease
        self.localVersionSummary = localVersionSummary
        self.comparison = comparison
    }

    public var title: String {
        switch comparison {
        case .updateAvailable:
            "Update available: \(latestRelease.tagName)"
        case .currentOrNewer:
            "Runtime appears current: \(latestRelease.tagName)"
        case .unknownLocalVersion:
            "Latest \(target.displayName) release: \(latestRelease.tagName)"
        case .unknownLatestVersion:
            "Latest \(target.displayName) release found"
        }
    }

    public var detail: String {
        switch comparison {
        case .updateAvailable:
            "The selected runtime appears older than \(latestRelease.tagName). Review the update command manually before changing the runtime."
        case .currentOrNewer:
            "The selected runtime version appears to be at least as new as the latest published release."
        case .unknownLocalVersion:
            "Lantern could not compare the selected runtime version. Run Check Runtime first, then check for updates again."
        case .unknownLatestVersion:
            "Lantern found the latest release metadata, but could not read a comparable release build number."
        }
    }
}

public struct RuntimeUpdateAvailabilityChecker: Sendable {
    public let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func check(
        target: RuntimeUpdateCheckTarget,
        localVersionSummary: String?
    ) async throws -> RuntimeUpdateAvailability {
        let release = try await latestRelease(for: target)
        let comparison = compare(
            localBuild: Self.buildNumber(in: localVersionSummary),
            latestBuild: Self.buildNumber(in: release.tagName)
        )

        return RuntimeUpdateAvailability(
            target: target,
            latestRelease: release,
            localVersionSummary: localVersionSummary,
            comparison: comparison
        )
    }

    private func latestRelease(for target: RuntimeUpdateCheckTarget) async throws -> RuntimeLatestRelease {
        var request = URLRequest(url: target.latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Hazakura-Lantern", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 8

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RuntimeUpdateAvailabilityError.nonHTTPResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw RuntimeUpdateAvailabilityError.httpStatus(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(GitHubLatestReleasePayload.self, from: data)
        return RuntimeLatestRelease(
            tagName: payload.tagName,
            htmlURL: payload.htmlURL,
            publishedAt: payload.publishedAt
        )
    }

    private func compare(localBuild: Int?, latestBuild: Int?) -> RuntimeUpdateAvailability.Comparison {
        guard let latestBuild else {
            return .unknownLatestVersion
        }

        guard let localBuild else {
            return .unknownLocalVersion
        }

        return localBuild < latestBuild ? .updateAvailable : .currentOrNewer
    }

    static func buildNumber(in text: String?) -> Int? {
        guard let text else {
            return nil
        }

        let pattern = #"(?i)\bb([0-9]+)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let buildRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return Int(text[buildRange])
    }
}

public enum RuntimeUpdateAvailabilityError: LocalizedError, Equatable {
    case nonHTTPResponse
    case httpStatus(Int)

    public var errorDescription: String? {
        switch self {
        case .nonHTTPResponse:
            "Update check did not receive an HTTP response."
        case .httpStatus(let statusCode):
            "Update check returned HTTP \(statusCode)."
        }
    }
}

private struct GitHubLatestReleasePayload: Decodable {
    let tagName: String
    let htmlURL: URL?
    let publishedAt: Date?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case publishedAt = "published_at"
    }
}
