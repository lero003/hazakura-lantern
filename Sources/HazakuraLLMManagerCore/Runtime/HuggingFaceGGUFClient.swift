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

        let response: LossyDecodableArray<ModelSearchResponse> = try await decode(components)
        return response.elements.compactMap { item in
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

        let response: LossyDecodableArray<TreeEntryResponse> = try await decode(components)
        let files = response.elements.compactMap { entry -> HuggingFaceGGUFFile? in
            guard Self.isFileTreeEntry(entry.type),
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

    private static func isFileTreeEntry(_ type: String?) -> Bool {
        type?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "file"
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

    private struct LossyDecodableArray<Element: Decodable>: Decodable {
        var elements: [Element]

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            var elements: [Element] = []

            while !container.isAtEnd {
                if let element = try? container.decode(Element.self) {
                    elements.append(element)
                } else {
                    _ = try container.decode(DiscardedJSONValue.self)
                }
            }

            self.elements = elements
        }
    }

    private struct DiscardedJSONValue: Decodable {
        init(from decoder: Decoder) throws {
            if var container = try? decoder.unkeyedContainer() {
                while !container.isAtEnd {
                    _ = try container.decode(DiscardedJSONValue.self)
                }
                return
            }

            if let container = try? decoder.container(keyedBy: DiscardedCodingKey.self) {
                for key in container.allKeys {
                    _ = try container.decode(DiscardedJSONValue.self, forKey: key)
                }
                return
            }

            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                return
            }
            if (try? container.decode(Bool.self)) != nil {
                return
            }
            if (try? container.decode(Double.self)) != nil {
                return
            }
            _ = try container.decode(String.self)
        }
    }

    private struct DiscardedCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
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

        enum CodingKeys: String, CodingKey {
            case id
            case modelId
            case author
            case lastModified
            case createdAt
            case tags
            case gated
            case downloads
            case likes
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = Self.decodeOptionalString(from: container, forKey: .id)
            modelId = Self.decodeOptionalString(from: container, forKey: .modelId)
            author = Self.decodeOptionalString(from: container, forKey: .author)
            lastModified = Self.decodeOptionalString(from: container, forKey: .lastModified)
            createdAt = Self.decodeOptionalString(from: container, forKey: .createdAt)
            tags = Self.decodeOptionalStringArray(from: container, forKey: .tags)
            gated = Self.decodeGatedValue(from: container)
            downloads = Self.decodeOptionalInt(from: container, forKey: .downloads)
            likes = Self.decodeOptionalInt(from: container, forKey: .likes)
        }

        private static func decodeGatedValue(from container: KeyedDecodingContainer<CodingKeys>) -> Bool? {
            if let value = try? container.decodeIfPresent(Bool.self, forKey: .gated) {
                return value
            }

            guard let rawValue = try? container.decodeIfPresent(String.self, forKey: .gated) else {
                return nil
            }

            switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "manual", "auto":
                return true
            case "false":
                return false
            default:
                return nil
            }
        }

        private static func decodeOptionalString(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) -> String? {
            try? container.decodeIfPresent(String.self, forKey: key)
        }

        private static func decodeOptionalStringArray(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) -> [String]? {
            try? container.decodeIfPresent([String].self, forKey: key)
        }

        private static func decodeOptionalInt(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) -> Int? {
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return normalizedCount(value)
            }

            guard let rawValue = try? container.decodeIfPresent(String.self, forKey: key) else {
                return nil
            }

            return normalizedCount(Int(rawValue.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        private static func normalizedCount(_ value: Int?) -> Int? {
            guard let value, value >= 0 else {
                return nil
            }

            return value
        }
    }

    private struct TreeEntryResponse: Decodable {
        var type: String?
        var path: String?
        var size: Int64?

        enum CodingKeys: String, CodingKey {
            case type
            case path
            case size
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = Self.decodeOptionalString(from: container, forKey: .type)
            path = Self.decodeOptionalString(from: container, forKey: .path)
            size = Self.decodeOptionalInt64(from: container, forKey: .size)
        }

        private static func decodeOptionalString(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) -> String? {
            try? container.decodeIfPresent(String.self, forKey: key)
        }

        private static func decodeOptionalInt64(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) -> Int64? {
            if let value = try? container.decodeIfPresent(Int64.self, forKey: key) {
                return value
            }

            guard let rawValue = try? container.decodeIfPresent(String.self, forKey: key) else {
                return nil
            }

            return Int64(rawValue.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
