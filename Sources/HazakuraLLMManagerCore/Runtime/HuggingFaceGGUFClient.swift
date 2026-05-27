import Foundation

public protocol HuggingFaceGGUFSearching: Sendable {
    func searchRepositories(query: String, limit: Int) async throws -> [HuggingFaceGGUFRepository]
    func listGGUFFiles(repoID: String) async throws -> [HuggingFaceGGUFFile]
}

public struct HuggingFaceGGUFClient: HuggingFaceGGUFSearching {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = URL(string: "https://huggingface.co")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func searchRepositories(query: String, limit: Int = 20) async throws -> [HuggingFaceGGUFRepository] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw GGUFAcquisitionError.emptySearchQuery
        }

        var components = try components(path: "/api/models")
        components.queryItems = [
            URLQueryItem(name: "search", value: trimmedQuery),
            URLQueryItem(name: "filter", value: "gguf"),
            URLQueryItem(name: "limit", value: String(max(1, min(limit, 50))))
        ]

        let response: [ModelSearchResponse] = try await decode(components)
        return response.compactMap { item in
            guard let normalizedID = normalizedRepoID(from: [item.id, item.modelId]) else {
                return nil
            }

            return HuggingFaceGGUFRepository(
                id: normalizedID,
                author: item.author,
                lastModified: item.lastModified ?? item.createdAt,
                tags: item.tags ?? [],
                isGated: item.gated,
                downloads: item.downloads,
                likes: item.likes
            )
        }
    }

    private func normalizedRepoID(from candidates: [String?]) -> String? {
        for candidate in candidates {
            guard let candidate,
                  let normalizedID = try? normalizeRepoID(candidate)
            else {
                continue
            }

            return normalizedID
        }

        return nil
    }

    public func listGGUFFiles(repoID: String) async throws -> [HuggingFaceGGUFFile] {
        let normalizedRepoID = try normalizeRepoID(repoID)
        let path = "/api/models/\(normalizedRepoID)/tree/main"
        var components = try components(path: path)
        components.queryItems = [
            URLQueryItem(name: "recursive", value: "true"),
            URLQueryItem(name: "expand", value: "false")
        ]

        let response: [TreeEntryResponse] = try await decode(components)
        let files = response.compactMap { entry -> HuggingFaceGGUFFile? in
            guard entry.type == "file",
                  let path = entry.path,
                  path.lowercased().hasSuffix(".gguf"),
                  Self.isSafeTreeFilePath(path)
            else {
                return nil
            }

            return HuggingFaceGGUFFile(
                repoID: normalizedRepoID,
                path: path,
                sizeBytes: Self.normalizedFileSize(entry.size),
                downloadURL: downloadURL(repoID: normalizedRepoID, filePath: path)
            )
        }
        .sorted { lhs, rhs in
            lhs.path.localizedStandardCompare(rhs.path) == .orderedAscending
        }

        guard !files.isEmpty else {
            throw GGUFAcquisitionError.noGGUFFilesFound(normalizedRepoID)
        }

        return files
    }

    private static func normalizedFileSize(_ size: Int64?) -> Int64? {
        guard let size, size > 0 else {
            return nil
        }

        return size
    }

    private static func isSafeTreeFilePath(_ path: String) -> Bool {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard !components.isEmpty else {
            return false
        }

        return components.allSatisfy { component in
            isSafePathComponent(String(component))
        }
    }

    private func decode<Value: Decodable>(_ components: URLComponents) async throws -> Value {
        guard let url = components.url else {
            throw GGUFAcquisitionError.invalidBaseURL
        }

        let (data, response) = try await session.data(from: url)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw GGUFAcquisitionError.invalidHTTPStatus(httpResponse.statusCode)
        }

        return try decoder.decode(Value.self, from: data)
    }

    private func components(path: String) throws -> URLComponents {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw GGUFAcquisitionError.invalidBaseURL
        }

        components.path = path
        return components
    }

    private func normalizeRepoID(_ repoID: String) throws -> String {
        let components = repoID.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count == 2,
              components.allSatisfy({
                  Self.isSafePathComponent(String($0))
              })
        else {
            throw GGUFAcquisitionError.invalidRepositoryID(repoID)
        }

        return components.joined(separator: "/")
    }

    private static func isSafePathComponent(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !value.isEmpty
            && value == trimmed
            && value != "."
            && value != ".."
            && !value.contains("/")
            && !value.contains("\\")
    }

    private func downloadURL(repoID: String, filePath: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = "/" + (repoID.split(separator: "/").map(String.init) + ["resolve", "main"] + filePath.split(separator: "/").map(String.init))
            .joined(separator: "/")
        return components.url!
    }

    private struct ModelSearchResponse: Decodable {
        var id: String?
        var modelId: String?
        var author: String?
        var lastModified: String?
        var createdAt: String?
        var tags: [String]?
        var gated: Bool?
        var downloads: Int?
        var likes: Int?
    }

    private struct TreeEntryResponse: Decodable {
        var type: String?
        var path: String?
        var size: Int64?
    }
}
