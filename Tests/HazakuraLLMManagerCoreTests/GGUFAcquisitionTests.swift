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

    func testDestinationURLRejectsBackslashStyleRepoID() {
        let file = HuggingFaceGGUFFile(
            repoID: "owner\\name/model-GGUF",
            path: "model.gguf",
            downloadURL: URL(string: "https://example.com/model.gguf")!
        )

        XCTAssertThrowsError(
            try GGUFDownloadDestination.destinationURL(
                for: file,
                in: URL(fileURLWithPath: "/Models")
            )
        ) { error in
            XCTAssertEqual(error as? GGUFAcquisitionError, .invalidRepositoryID("owner\\name/model-GGUF"))
        }
    }

    func testDestinationURLRejectsUnsafeGGUFFilePaths() {
        let unsafePaths = [
            "../escape.gguf",
            "/absolute.gguf",
            "nested//empty.gguf",
            "nested/./dot.gguf",
            "nested/../parent.gguf",
            "nested\\slash.gguf",
            "not-a-gguf.txt"
        ]

        for path in unsafePaths {
            let file = HuggingFaceGGUFFile(
                repoID: "owner/model-GGUF",
                path: path,
                downloadURL: URL(string: "https://example.com/model.gguf")!
            )

            XCTAssertThrowsError(
                try GGUFDownloadDestination.destinationURL(
                    for: file,
                    in: URL(fileURLWithPath: "/Models")
                )
            ) { error in
                XCTAssertEqual(error as? GGUFAcquisitionError, .invalidGGUFFilePath(path))
            }
        }
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

    func testClientSearchFiltersUnsupportedRepositoryIDs() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {"id": "owner/model-GGUF", "author": "owner"},
                  {"id": "owner", "author": "owner"},
                  {"id": "owner//model-GGUF", "author": "owner"},
                  {"id": "owner/../model-GGUF", "author": "owner"},
                  {"id": "owner\\\\name/model-GGUF", "author": "owner"},
                  {"modelId": "fallback/model-GGUF", "author": "fallback"}
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

        XCTAssertEqual(results.map(\.id), ["owner/model-GGUF", "fallback/model-GGUF"])
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

    func testClientIgnoresUnsafeGGUFTreePaths() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {"type": "file", "path": "../escape.gguf", "size": 10},
                  {"type": "file", "path": "/absolute.gguf", "size": 11},
                  {"type": "file", "path": "nested//empty.gguf", "size": 12},
                  {"type": "file", "path": "nested/./dot.gguf", "size": 13},
                  {"type": "file", "path": "nested/../parent.gguf", "size": 14},
                  {"type": "file", "path": "nested\\\\slash.gguf", "size": 15},
                  {"type": "file", "path": "nested/model-Q4.gguf", "size": 1234}
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

        XCTAssertEqual(files.map(\.path), ["nested/model-Q4.gguf"])
    }

    func testClientIgnoresIncompleteTreeEntries() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {"type": "file", "size": 100},
                  {"path": "missing-type.gguf", "size": 101},
                  {"type": "file", "path": "nested/model-Q4.gguf", "size": 1234}
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

        XCTAssertEqual(files.map(\.path), ["nested/model-Q4.gguf"])
    }

    func testClientReportsNoGGUFFilesWhenRepositoryTreeHasNoSupportedFiles() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {"type": "file", "path": "README.md", "size": 100},
                  {"type": "directory", "path": "nested"},
                  {"type": "file", "path": "nested/model.bin", "size": 200},
                  {"type": "file", "path": "../unsafe.gguf", "size": 300}
                ]
                """.utf8),
                [:]
            )
        }
        let client = HuggingFaceGGUFClient(
            baseURL: URL(string: "https://huggingface.test")!,
            session: session
        )

        do {
            _ = try await client.listGGUFFiles(repoID: "owner/model-GGUF")
            XCTFail("Expected repositories without supported .gguf files to fail clearly.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .noGGUFFilesFound("owner/model-GGUF"))
        }
    }

    func testClientMapsHuggingFaceHTTPFailures() async throws {
        let session = makeSession { _ in
            (
                503,
                Data("""
                {"error": "temporarily unavailable"}
                """.utf8),
                [:]
            )
        }
        let client = HuggingFaceGGUFClient(
            baseURL: URL(string: "https://huggingface.test")!,
            session: session
        )

        do {
            _ = try await client.searchRepositories(query: "qwen", limit: 10)
            XCTFail("Expected HTTP failures to map to a typed GGUF acquisition error.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .invalidHTTPStatus(503))
        }
    }

    func testClientRejectsUnsafeRepoIDsBeforeListingFiles() async throws {
        let session = makeSession { _ in
            XCTFail("Unsafe repository ids should not reach the public API request.")
            return (200, Data("[]".utf8), [:])
        }
        let client = HuggingFaceGGUFClient(
            baseURL: URL(string: "https://huggingface.test")!,
            session: session
        )

        let unsafeRepoIDs = [
            "owner",
            "owner//model-GGUF",
            "owner/./model-GGUF",
            "owner/../model-GGUF",
            "owner\\name/model-GGUF"
        ]

        for repoID in unsafeRepoIDs {
            do {
                _ = try await client.listGGUFFiles(repoID: repoID)
                XCTFail("Expected \(repoID) to be rejected.")
            } catch let error as GGUFAcquisitionError {
                XCTAssertEqual(error, .invalidRepositoryID(repoID))
            }
        }
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

    func testDownloaderCancellationKeepsPartialFileForResume() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        let flushedBytes = 64 * 1_024
        let responseBody = Data(repeating: 0x41, count: flushedBytes + 10)

        let session = makeSession { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Range"))
            return (
                200,
                responseBody,
                [
                    "Content-Length": String(responseBody.count)
                ]
            )
        }
        let downloader = GGUFFileDownloader(session: session)
        var progressValues: [GGUFDownloadProgress] = []
        var downloadTask: Task<URL, Error>!

        downloadTask = Task {
            try await downloader.download(
                GGUFDownloadRequest(
                    remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                    destinationURL: destination,
                    expectedBytes: Int64(responseBody.count)
                )
            ) { progress in
                progressValues.append(progress)
                if progress.bytesWritten >= Int64(flushedBytes) {
                    downloadTask.cancel()
                }
            }
        }

        do {
            _ = try await downloadTask.value
            XCTFail("Expected cancellation to stop the active GGUF download.")
        } catch is CancellationError {
        }

        let partialSize = try FileManager.default.attributesOfItem(atPath: partial.path)[.size] as? NSNumber
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(partialSize?.int64Value, Int64(flushedBytes))
        XCTAssertEqual(progressValues.last?.bytesWritten, Int64(flushedBytes))
    }

    func testDownloaderRejectsNonFileSuccessStatusWithoutCompletingPartial() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        try Data("partial".utf8).write(to: partial)

        let session = makeSession { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), "bytes=7-")
            return (
                204,
                Data(),
                [:]
            )
        }
        let downloader = GGUFFileDownloader(session: session)

        do {
            _ = try await downloader.download(
                GGUFDownloadRequest(
                    remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                    destinationURL: destination,
                    expectedBytes: 42
                )
            ) { _ in }
            XCTFail("Expected non-file success status to be rejected.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .invalidHTTPStatus(204))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: partial, encoding: .utf8), "partial")
    }

    func testDownloaderRejectsIncompleteExpectedDownloadWithoutCompletingPartial() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)

        let session = makeSession { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Range"))
            return (
                200,
                Data("short".utf8),
                [
                    "Content-Length": "5"
                ]
            )
        }
        let downloader = GGUFFileDownloader(session: session)

        do {
            _ = try await downloader.download(
                GGUFDownloadRequest(
                    remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                    destinationURL: destination,
                    expectedBytes: 11
                )
            ) { _ in }
            XCTFail("Expected incomplete GGUF downloads to stay partial.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .incompleteDownload(expectedBytes: 11, actualBytes: 5))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: partial, encoding: .utf8), "short")
    }

    func testDownloaderRejectsEmptySuccessResponseWithoutCompletingDestination() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)

        let session = makeSession { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Range"))
            return (
                200,
                Data(),
                [
                    "Content-Length": "0"
                ]
            )
        }
        let downloader = GGUFFileDownloader(session: session)

        do {
            _ = try await downloader.download(
                GGUFDownloadRequest(
                    remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                    destinationURL: destination
                )
            ) { _ in }
            XCTFail("Expected empty GGUF responses to fail instead of completing.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .emptyDownload)
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: partial.path))
    }

    func testDownloaderRemovesStalePartialWhenDestinationIsAlreadyComplete() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        try Data("complete".utf8).write(to: destination)
        try Data("stale".utf8).write(to: partial)

        let session = makeSession { _ in
            XCTFail("Completed downloads should not start a network request.")
            return (200, Data(), [:])
        }
        let downloader = GGUFFileDownloader(session: session)
        var progressValues: [GGUFDownloadProgress] = []

        let downloadedURL = try await downloader.download(
            GGUFDownloadRequest(
                remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                destinationURL: destination,
                expectedBytes: 8
            )
        ) { progress in
            progressValues.append(progress)
        }

        XCTAssertEqual(downloadedURL, destination)
        XCTAssertEqual(try String(contentsOf: destination, encoding: .utf8), "complete")
        XCTAssertFalse(FileManager.default.fileExists(atPath: partial.path))
        XCTAssertEqual(progressValues, [GGUFDownloadProgress(bytesWritten: 8, totalBytes: 8)])
    }

    func testDownloaderPromotesCompletePartialFileWithoutNetworkRequest() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        try Data("complete".utf8).write(to: partial)

        let session = makeSession { _ in
            XCTFail("Complete partial downloads should not start a network request.")
            return (416, Data(), [:])
        }
        let downloader = GGUFFileDownloader(session: session)
        var progressValues: [GGUFDownloadProgress] = []

        let downloadedURL = try await downloader.download(
            GGUFDownloadRequest(
                remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                destinationURL: destination,
                expectedBytes: 8
            )
        ) { progress in
            progressValues.append(progress)
        }

        XCTAssertEqual(downloadedURL, destination)
        XCTAssertEqual(try String(contentsOf: destination, encoding: .utf8), "complete")
        XCTAssertFalse(FileManager.default.fileExists(atPath: partial.path))
        XCTAssertEqual(progressValues, [GGUFDownloadProgress(bytesWritten: 8, totalBytes: 8)])
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
