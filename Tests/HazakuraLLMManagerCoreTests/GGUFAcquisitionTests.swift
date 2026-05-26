import XCTest
@testable import HazakuraLLMManagerCore

final class GGUFAcquisitionTests: XCTestCase {
    func testDestinationURLUsesOwnerRepoAndFileNameOnly() throws {
        let file = HuggingFaceGGUFFile(
            repoID: "owner/model-GGUF",
            path: "nested/model-Q4_K_M.gguf",
            downloadURL: URL(string: "https://example.com/model.gguf")!
        )

        let destination = try GGUFDownloadDestination.destinationURL(
            for: file,
            in: URL(fileURLWithPath: "/Models")
        )

        XCTAssertEqual(destination.path, "/Models/owner/model-GGUF/model-Q4_K_M.gguf")
    }

    func testDestinationURLRejectsInvalidRepoID() {
        let file = HuggingFaceGGUFFile(
            repoID: "owner",
            path: "model.gguf",
            downloadURL: URL(string: "https://example.com/model.gguf")!
        )

        XCTAssertThrowsError(
            try GGUFDownloadDestination.destinationURL(
                for: file,
                in: URL(fileURLWithPath: "/Models")
            )
        )
    }

    func testConfigurationStorePersistsGGUFDownloadDirectory() {
        let suiteName = "HazakuraLLMManagerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ConfigurationStore(defaults: defaults)

        XCTAssertEqual(store.loadGGUFDownloadDirectory(), "")

        store.saveGGUFDownloadDirectory("  /Users/me/Models  ")
        XCTAssertEqual(store.loadGGUFDownloadDirectory(), "/Users/me/Models")

        store.saveGGUFDownloadDirectory(" ")
        XCTAssertEqual(store.loadGGUFDownloadDirectory(), "")
    }

    func testClientSearchesGGUFRepositories() async throws {
        let session = makeSession { request in
            XCTAssertEqual(request.url?.path, "/api/models")
            XCTAssertTrue(request.url?.query?.contains("filter=gguf") == true)
            return (
                200,
                Data("""
                [
                  {
                    "id": "owner/model-GGUF",
                    "author": "owner",
                    "tags": ["gguf"],
                    "downloads": 12,
                    "likes": 3,
                    "lastModified": "2026-05-26T00:00:00.000Z",
                    "gated": false
                  }
                ]
                """.utf8),
                [:]
            )
        }
        let client = HuggingFaceGGUFClient(
            baseURL: URL(string: "https://huggingface.test")!,
            session: session
        )

        let results = try await client.searchRepositories(query: "qwen", limit: 10)

        XCTAssertEqual(
            results,
            [
                HuggingFaceGGUFRepository(
                    id: "owner/model-GGUF",
                    author: "owner",
                    lastModified: "2026-05-26T00:00:00.000Z",
                    tags: ["gguf"],
                    isGated: false,
                    downloads: 12,
                    likes: 3
                )
            ]
        )
    }

    func testClientListsGGUFFilesWithSizesAndDownloadURLs() async throws {
        let session = makeSession { request in
            XCTAssertEqual(request.url?.path, "/api/models/owner/model-GGUF/tree/main")
            return (
                200,
                Data("""
                [
                  {"type": "file", "path": "README.md", "size": 42},
                  {"type": "file", "path": "nested/model-Q4.gguf", "size": 1234},
                  {"type": "directory", "path": "folder"}
                ]
                """.utf8),
                [:]
            )
        }
        let client = HuggingFaceGGUFClient(
            baseURL: URL(string: "https://huggingface.test")!,
            session: session
        )

        let files = try await client.listGGUFFiles(repoID: "owner/model-GGUF")

        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files[0].repoID, "owner/model-GGUF")
        XCTAssertEqual(files[0].path, "nested/model-Q4.gguf")
        XCTAssertEqual(files[0].sizeBytes, 1234)
        XCTAssertEqual(
            files[0].downloadURL.absoluteString,
            "https://huggingface.test/owner/model-GGUF/resolve/main/nested/model-Q4.gguf"
        )
    }

    func testDownloaderResumesExistingPartialFileWithRangeRequest() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        try Data("hello ".utf8).write(to: partial)

        let session = makeSession { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), "bytes=6-")
            return (
                206,
                Data("world".utf8),
                [
                    "Content-Range": "bytes 6-10/11",
                    "Content-Length": "5"
                ]
            )
        }
        let downloader = GGUFFileDownloader(session: session)
        var progressValues: [GGUFDownloadProgress] = []

        let downloadedURL = try await downloader.download(
            GGUFDownloadRequest(
                remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                destinationURL: destination,
                expectedBytes: 11
            )
        ) { progress in
            progressValues.append(progress)
        }

        XCTAssertEqual(downloadedURL, destination)
        XCTAssertEqual(try String(contentsOf: destination, encoding: .utf8), "hello world")
        XCTAssertFalse(FileManager.default.fileExists(atPath: partial.path))
        XCTAssertEqual(progressValues.last?.bytesWritten, 11)
        XCTAssertEqual(progressValues.last?.totalBytes, 11)
        XCTAssertEqual(progressValues.last?.fractionCompleted, 1)
    }

    func testDownloaderRestartsPartialFileWhenServerIgnoresRangeRequest() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        try Data("stale ".utf8).write(to: partial)

        let session = makeSession { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), "bytes=6-")
            return (
                200,
                Data("fresh".utf8),
                [
                    "Content-Length": "5"
                ]
            )
        }
        let downloader = GGUFFileDownloader(session: session)

        let downloadedURL = try await downloader.download(
            GGUFDownloadRequest(
                remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                destinationURL: destination,
                expectedBytes: 5
            )
        ) { _ in }

        XCTAssertEqual(downloadedURL, destination)
        XCTAssertEqual(try String(contentsOf: destination, encoding: .utf8), "fresh")
        XCTAssertFalse(FileManager.default.fileExists(atPath: partial.path))
    }

    private func makeSession(
        handler: @escaping @Sendable (URLRequest) throws -> (Int, Data, [String: String])
    ) -> URLSession {
        MockURLProtocol.handler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class MockURLProtocol: URLProtocol {
    static var handler: (@Sendable (URLRequest) throws -> (Int, Data, [String: String]))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: GGUFAcquisitionError.fileSystem("Missing mock handler."))
            return
        }

        do {
            let (statusCode, data, headers) = try handler(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
