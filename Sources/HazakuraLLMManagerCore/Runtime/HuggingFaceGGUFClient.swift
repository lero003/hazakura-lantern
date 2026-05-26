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
            guard let id = item.id ?? item.modelId,
                  id.contains("/")
            else {
                return nil
            }

            return HuggingFaceGGUFRepository(
                id: id,
                author: item.author,
                lastModified: item.lastModified ?? item.createdAt,
                tags: item.tags ?? [],
                isGated: item.gated,
                downloads: item.downloads,
                likes: item.likes
            )
        }
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
                  entry.path.lowercased().hasSuffix(".gguf")
            else {
                return nil
            }

            return HuggingFaceGGUFFile(
                repoID: normalizedRepoID,
                path: entry.path,
                sizeBytes: entry.size,
                downloadURL: downloadURL(repoID: normalizedRepoID, filePath: entry.path)
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
              components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        else {
            throw GGUFAcquisitionError.invalidRepositoryID(repoID)
        }

        return components.joined(separator: "/")
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
        var type: String
        var path: String
        var size: Int64?
    }
}
