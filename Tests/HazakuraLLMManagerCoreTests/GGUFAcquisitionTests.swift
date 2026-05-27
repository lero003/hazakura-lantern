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
        let invalidRepoIDs = [
            "owner",
            " owner/model-GGUF",
            "owner/model-GGUF ",
            "owner /model-GGUF"
        ]

        for repoID in invalidRepoIDs {
            let file = HuggingFaceGGUFFile(
                repoID: repoID,
                path: "model.gguf",
                downloadURL: URL(string: "https://example.com/model.gguf")!
            )

            XCTAssertThrowsError(
                try GGUFDownloadDestination.destinationURL(
                    for: file,
                    in: URL(fileURLWithPath: "/Models")
                )
            ) { error in
                XCTAssertEqual(error as? GGUFAcquisitionError, .invalidRepositoryID(repoID))
            }
        }
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
            " nested/model.gguf",
            "nested/model.gguf ",
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

    func testDownloadDirectoryURLRequiresAbsoluteOrTildeExpandedPath() throws {
        let absoluteURL = try GGUFDownloadDestination.downloadDirectoryURL(
            fromPath: "  /Users/me/Models  "
        )
        XCTAssertEqual(absoluteURL.path, "/Users/me/Models")

        let tildeURL = try GGUFDownloadDestination.downloadDirectoryURL(
            fromPath: "~/Models"
        )
        XCTAssertEqual(
            tildeURL.path,
            URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
                .appendingPathComponent("Models", isDirectory: true)
                .path
        )

        for path in ["", "   ", "Models", "nested/Models"] {
            XCTAssertThrowsError(
                try GGUFDownloadDestination.downloadDirectoryURL(fromPath: path)
            ) { error in
                XCTAssertEqual(error as? GGUFAcquisitionError, .invalidDownloadDirectory(path))
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
                  {"id": " owner/model-GGUF", "author": "owner"},
                  {"id": "owner/model-GGUF ", "author": "owner"},
                  {"id": "owner /model-GGUF", "author": "owner"},
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

    func testClientSearchFallsBackToModelIDWhenIDIsUnsupported() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {
                    "id": "owner//model-GGUF",
                    "modelId": "fallback/model-GGUF",
                    "author": "fallback"
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

        XCTAssertEqual(results.map(\.id), ["fallback/model-GGUF"])
    }

    func testClientSearchToleratesStringGatedValues() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {"id": "owner/auto-gated-GGUF", "gated": "auto"},
                  {"id": "owner/manual-gated-GGUF", "gated": "manual"},
                  {"id": "owner/open-GGUF", "gated": "false"},
                  {"id": "owner/unknown-gated-GGUF", "gated": "unexpected"}
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
            results.map(\.id),
            [
                "owner/auto-gated-GGUF",
                "owner/manual-gated-GGUF",
                "owner/open-GGUF",
                "owner/unknown-gated-GGUF"
            ]
        )
        XCTAssertEqual(results.map(\.isGated), [true, true, false, nil])
    }

    func testClientSearchToleratesStringAndMalformedNumericMetadata() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {"id": "owner/string-counts-GGUF", "downloads": "12", "likes": " 3 "},
                  {"id": "owner/malformed-counts-GGUF", "downloads": "many", "likes": {"count": 1}},
                  {"id": "owner/negative-counts-GGUF", "downloads": -1, "likes": "-2"}
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
            results.map(\.id),
            [
                "owner/string-counts-GGUF",
                "owner/malformed-counts-GGUF",
                "owner/negative-counts-GGUF"
            ]
        )
        XCTAssertEqual(results.map(\.downloads), [12, nil, nil])
        XCTAssertEqual(results.map(\.likes), [3, nil, nil])
    }

    func testClientSearchTreatsMalformedAdvisoryMetadataAsOptional() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {
                    "id": "owner/malformed-advisory-GGUF",
                    "author": {"name": "owner"},
                    "lastModified": 42,
                    "createdAt": ["2026-05-28"],
                    "tags": [{"name": "gguf"}]
                  },
                  {
                    "id": "owner/valid-advisory-GGUF",
                    "author": "owner",
                    "lastModified": "2026-05-28T00:00:00.000Z",
                    "tags": ["gguf", "qwen"]
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

        XCTAssertEqual(results.map(\.id), ["owner/malformed-advisory-GGUF", "owner/valid-advisory-GGUF"])
        XCTAssertNil(results[0].author)
        XCTAssertNil(results[0].lastModified)
        XCTAssertEqual(results[0].tags, [])
        XCTAssertEqual(results[1].author, "owner")
        XCTAssertEqual(results[1].lastModified, "2026-05-28T00:00:00.000Z")
        XCTAssertEqual(results[1].tags, ["gguf", "qwen"])
    }

    func testClientSearchSkipsMalformedIdentityFieldsWithoutDroppingCompatibleResults() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {"id": 42, "modelId": ["owner/model-GGUF"]},
                  {"id": "owner/valid-GGUF"},
                  {"id": {"name": "bad"}, "modelId": "fallback/valid-GGUF"}
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

        XCTAssertEqual(results.map(\.id), ["owner/valid-GGUF", "fallback/valid-GGUF"])
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
                  {"type": "file", "path": " nested/model.gguf", "size": 15},
                  {"type": "file", "path": "nested/model.gguf ", "size": 16},
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

    func testClientIgnoresMalformedTreeIdentityFields() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {"type": 42, "path": "numeric-type.gguf", "size": 100},
                  {"type": "file", "path": ["array-path.gguf"], "size": 101},
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

    func testClientTreatsNonPositiveTreeSizesAsUnknown() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {"type": "file", "path": "zero.gguf", "size": 0},
                  {"type": "file", "path": "negative.gguf", "size": -1},
                  {"type": "file", "path": "positive.gguf", "size": 1234}
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

        XCTAssertEqual(files.map(\.path), ["negative.gguf", "positive.gguf", "zero.gguf"])
        XCTAssertNil(files[0].sizeBytes)
        XCTAssertEqual(files[1].sizeBytes, 1234)
        XCTAssertNil(files[2].sizeBytes)
    }

    func testClientTreatsStringAndMalformedTreeSizesAsMetadataOnly() async throws {
        let session = makeSession { _ in
            (
                200,
                Data("""
                [
                  {"type": "file", "path": "malformed.gguf", "size": "many"},
                  {"type": "file", "path": "numeric-string.gguf", "size": " 1234 "}
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

        XCTAssertEqual(files.map(\.path), ["malformed.gguf", "numeric-string.gguf"])
        XCTAssertNil(files[0].sizeBytes)
        XCTAssertEqual(files[1].sizeBytes, 1234)
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
            " owner/model-GGUF",
            "owner/model-GGUF ",
            "owner /model-GGUF",
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

    func testDownloaderRejectsMismatchedResumeContentRangeWithoutCompletingPartial() async throws {
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
                Data("wrong".utf8),
                [
                    "Content-Range": "bytes 0-4/11",
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
            XCTFail("Expected mismatched resume ranges to fail before completing.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .invalidResumeRange(expectedStart: 6, actualStart: 0))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: partial, encoding: .utf8), "hello ")
    }

    func testDownloaderRejectsInvalidResumeContentRangeTotalBeforeAppending() async throws {
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
                    "Content-Range": "bytes 6-10/10",
                    "Content-Length": "5"
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
            XCTFail("Expected invalid Content-Range totals to fail before appending bytes.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .invalidResumeRange(expectedStart: 6, actualStart: nil))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: partial, encoding: .utf8), "hello ")
    }

    func testDownloaderRejectsUnexpectedPartialResponseWithoutCreatingPartialFile() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)

        let session = makeSession { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Range"))
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

        do {
            _ = try await downloader.download(
                GGUFDownloadRequest(
                    remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                    destinationURL: destination
                )
            ) { _ in }
            XCTFail("Expected unexpected partial responses to fail before creating a resume file.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .invalidResumeRange(expectedStart: 0, actualStart: 6))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: partial.path))
    }

    func testDownloaderRejectsShortResumeWhenContentRangeTotalIsKnown() async throws {
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
                Data("worl".utf8),
                [
                    "Content-Range": "bytes 6-9/11",
                    "Content-Length": "4"
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
            XCTFail("Expected a short resumed response to remain partial when Content-Range has the total size.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .incompleteDownload(expectedBytes: 11, actualBytes: 10))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: partial, encoding: .utf8), "hello worl")
    }

    func testDownloaderRejectsShortResumeWhenContentRangeEndIsKnown() async throws {
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
                Data("worl".utf8),
                [
                    "Content-Range": "bytes 6-10/*",
                    "Content-Length": "4"
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
            XCTFail("Expected a short resumed response to stay partial when Content-Range declares the response end.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .incompleteDownload(expectedBytes: 11, actualBytes: 10))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: partial, encoding: .utf8), "hello worl")
    }

    func testDownloaderRestartsPartialFileWhenServerIgnoresRangeRequest() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        try Data("old".utf8).write(to: partial)

        let session = makeSession { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), "bytes=3-")
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

    func testDownloaderRejectsShortContentLengthDownloadWithoutExpectedSize() async throws {
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
                    "Content-Length": "11"
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
            XCTFail("Expected short Content-Length downloads to stay partial.")
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

    func testDownloaderPromotesCompletePartialFileWhenRangeIsNotSatisfiable() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        try Data("complete".utf8).write(to: partial)

        let session = makeSession { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), "bytes=8-")
            return (
                416,
                Data(),
                [
                    "Content-Range": "bytes */8"
                ]
            )
        }
        let downloader = GGUFFileDownloader(session: session)
        var progressValues: [GGUFDownloadProgress] = []

        let downloadedURL = try await downloader.download(
            GGUFDownloadRequest(
                remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                destinationURL: destination
            )
        ) { progress in
            progressValues.append(progress)
        }

        XCTAssertEqual(downloadedURL, destination)
        XCTAssertEqual(try String(contentsOf: destination, encoding: .utf8), "complete")
        XCTAssertFalse(FileManager.default.fileExists(atPath: partial.path))
        XCTAssertEqual(progressValues, [GGUFDownloadProgress(bytesWritten: 8, totalBytes: 8)])
    }

    func testDownloaderRejectsRangeNotSatisfiableWhenExpectedSizeDisagrees() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        try Data("complete".utf8).write(to: partial)

        let session = makeSession { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), "bytes=8-")
            return (
                416,
                Data(),
                [
                    "Content-Range": "bytes */8"
                ]
            )
        }
        let downloader = GGUFFileDownloader(session: session)

        do {
            _ = try await downloader.download(
                GGUFDownloadRequest(
                    remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                    destinationURL: destination,
                    expectedBytes: 10
                )
            ) { _ in }
            XCTFail("Expected 416 completion to fail when server total disagrees with expected size.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .incompleteDownload(expectedBytes: 10, actualBytes: 8))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: partial, encoding: .utf8), "complete")
    }

    func testDownloaderKeepsPartialFileWhenRangeNotSatisfiableHasNoUsableTotal() async throws {
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
                416,
                Data(),
                [
                    "Content-Range": "bytes */*"
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
            XCTFail("Expected unusable 416 resume responses to fail without deleting retry bytes.")
        } catch let error as GGUFAcquisitionError {
            XCTAssertEqual(error, .invalidHTTPStatus(416))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: partial, encoding: .utf8), "partial")
    }

    func testDownloaderRejectsDirectoryDestinationWithoutDeletingIt() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        let session = makeSession { _ in
            XCTFail("Directory destinations should fail before starting a network request.")
            return (200, Data("fresh".utf8), [:])
        }
        let downloader = GGUFFileDownloader(session: session)

        do {
            _ = try await downloader.download(
                GGUFDownloadRequest(
                    remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                    destinationURL: destination,
                    expectedBytes: 5
                )
            ) { _ in }
            XCTFail("Expected existing destination directories to be rejected.")
        } catch let error as GGUFAcquisitionError {
            guard case .fileSystem(let message) = error else {
                XCTFail("Expected fileSystem error, got \(error).")
                return
            }
            XCTAssertTrue(message.contains(destination.path))
        }

        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testDownloaderRejectsDirectoryPartialFileWithoutDeletingIt() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        try FileManager.default.createDirectory(at: partial, withIntermediateDirectories: true)

        let session = makeSession { _ in
            XCTFail("Directory partial files should fail before starting a network request.")
            return (200, Data("fresh".utf8), [:])
        }
        let downloader = GGUFFileDownloader(session: session)

        do {
            _ = try await downloader.download(
                GGUFDownloadRequest(
                    remoteURL: URL(string: "https://huggingface.test/model.gguf")!,
                    destinationURL: destination,
                    expectedBytes: 5
                )
            ) { _ in }
            XCTFail("Expected existing partial-file directories to be rejected.")
        } catch let error as GGUFAcquisitionError {
            guard case .fileSystem(let message) = error else {
                XCTFail("Expected fileSystem error, got \(error).")
                return
            }
            XCTAssertTrue(message.contains(partial.path))
        }

        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: partial.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testDownloaderRestartsOversizedPartialFileWithoutRangeRequest() async throws {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("hazakura-gguf-download-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let destination = workspace.appendingPathComponent("model.gguf")
        let partial = GGUFDownloadDestination.partialURL(for: destination)
        try Data("oversized partial".utf8).write(to: partial)

        let session = makeSession { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Range"))
            return (
                200,
                Data("fresh".utf8),
                [
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
                expectedBytes: 5
            )
        ) { progress in
            progressValues.append(progress)
        }

        XCTAssertEqual(downloadedURL, destination)
        XCTAssertEqual(try String(contentsOf: destination, encoding: .utf8), "fresh")
        XCTAssertFalse(FileManager.default.fileExists(atPath: partial.path))
        XCTAssertEqual(progressValues.first, GGUFDownloadProgress(bytesWritten: 0, totalBytes: 5))
        XCTAssertEqual(progressValues.last, GGUFDownloadProgress(bytesWritten: 5, totalBytes: 5))
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
