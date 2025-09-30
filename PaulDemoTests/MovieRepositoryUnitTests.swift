//
//  MovieRepositoryUnitTests.swift
//  PaulDemoTests
//
//  Created by Paul Davis on 30/09/2025.
//

import XCTest
import CoreData
@testable import PaulDemo

typealias AppService = PaulDemo.Service

// MARK: - URLProtocol stub to intercept URLSession.shared
final class URLProtocolStub: URLProtocol {
    struct Stub {
        let response: HTTPURLResponse
        let data: Data
    }
    static var stubs: [URL: Stub] = [:]
    static var error: Error?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = URLProtocolStub.error {
            client?.urlProtocol(self, didFailWithError: error)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        guard let url = request.url, let stub = URLProtocolStub.stubs[url] else {
            client?.urlProtocol(self,
                                didFailWithError: NSError(domain: "URLProtocolStub", code: -1))
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        client?.urlProtocol(self, didReceive: stub.response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }

    // Helpers
    static func set(url: URL, statusCode: Int = 200, json: Any) {
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        let response = HTTPURLResponse(url: url, statusCode: statusCode,
                                       httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
        stubs[url] = Stub(response: response, data: data)
    }

    static func reset() {
        stubs = [:]
        error = nil
    }
}

// MARK: - In-memory Core Data stack with a MovieEntity (id,title,overview,posterPath)
private func makeInMemoryContainer() -> NSPersistentContainer {
    let model = NSManagedObjectModel()

    let entity = NSEntityDescription()
    entity.name = "MovieEntity"
    entity.managedObjectClassName = "NSManagedObject"

    let idAttr = NSAttributeDescription()
    idAttr.name = "id"
    idAttr.attributeType = .integer64AttributeType
    idAttr.isOptional = false

    let titleAttr = NSAttributeDescription()
    titleAttr.name = "title"
    titleAttr.attributeType = .stringAttributeType
    titleAttr.isOptional = true

    let overviewAttr = NSAttributeDescription()
    overviewAttr.name = "overview"
    overviewAttr.attributeType = .stringAttributeType
    overviewAttr.isOptional = true

    let posterPathAttr = NSAttributeDescription()
    posterPathAttr.name = "posterPath"
    posterPathAttr.attributeType = .stringAttributeType
    posterPathAttr.isOptional = true

    entity.properties = [idAttr, titleAttr, overviewAttr, posterPathAttr]
    model.entities = [entity]

    let container = NSPersistentContainer(name: "TestModel", managedObjectModel: model)
    let desc = NSPersistentStoreDescription()
    desc.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [desc]

    var loadErr: Error?
    let sema = DispatchSemaphore(value: 1)
    sema.wait()
    container.loadPersistentStores { _, error in
        loadErr = error
        sema.signal()
    }
    sema.wait()
    if let error = loadErr { fatalError("Failed to load in-memory store: \(error)") }
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    return container
}

// MARK: - Async throw helper
extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure @escaping () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()   // discard the value, we only care about the error
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch {
            // success: an error was thrown
        }
    }
}

// MARK: - Tests
final class MovieRepositoryImplTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Install stub into the shared session by registering globally.
        URLProtocol.registerClass(URLProtocolStub.self)
        URLProtocolStub.reset()
    }

    override func tearDown() {
        URLProtocolStub.reset()
        URLProtocol.unregisterClass(URLProtocolStub.self)
        super.tearDown()
    }

    // Convenience to build repo + container
    private func makeSUT() -> (repo: MovieRepositoryImpl, container: NSPersistentContainer) {
        let container = makeInMemoryContainer()
        let service = AppService() // concrete, but all traffic is intercepted by URLProtocolStub
        let repo = MovieRepositoryImpl(service: service, persistentContainer: container)
        return (repo, container)
    }

    // MARK: getMovies()

    func test_getMovies_networkSuccess_savesAndReturnsNetworkMovies() async throws {
        // Arrange
        let (repo, container) = makeSUT()
        let url = URL(string: "https://api.themoviedb.org/3/movie/popular?api_key=e59fa91697a3e04422635ab8e092d648&language=en-US&page=1")!

        // Stub a MovieResponse payload
        URLProtocolStub.set(url: url, json: [
            "results": [
                ["id": 1, "title": "One", "overview": "A", "poster_path": "p1"],
                ["id": 2, "title": "Two", "overview": "B", "poster_path": NSNull()]
            ]
        ])

        // Act
        let movies = try await repo.getMovies()

        // Assert returned data
        XCTAssertEqual(movies.map(\.id), [1, 2])
        XCTAssertEqual(movies.first?.posterPath, "p1")
        XCTAssertNil(movies.last?.posterPath)

        // Assert Core Data got persisted
        let ctx = container.viewContext
        let fr = NSFetchRequest<NSManagedObject>(entityName: "MovieEntity")
        let saved = try ctx.fetch(fr)
        XCTAssertEqual(saved.count, 2)
        let savedIds = saved.compactMap { $0.value(forKey: "id") as? Int64 }.sorted()
        XCTAssertEqual(savedIds, [1, 2])
    }

    func test_getMovies_networkFails_returnsCacheWhenAvailable() async throws {
        // Arrange
        let (repo, container) = makeSUT()
        // Force network error
        URLProtocolStub.error = NSError(domain: "net", code: -1)

        // Seed cache
        let ctx = container.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "MovieEntity", in: ctx)!
        let e1 = NSManagedObject(entity: entity, insertInto: ctx)
        e1.setValue(Int64(10), forKey: "id")
        e1.setValue("Ten", forKey: "title")
        e1.setValue("T", forKey: "overview")

        let e2 = NSManagedObject(entity: entity, insertInto: ctx)
        e2.setValue(Int64(11), forKey: "id")
        e2.setValue("Eleven", forKey: "title")
        e2.setValue("E", forKey: "overview")

        try ctx.save()

        // Act
        let cached = try await repo.getMovies()

        // Assert cache returned
        XCTAssertEqual(Set(cached.map(\.id)), Set([10, 11]))
    }

    func test_getMovies_networkFails_andCacheEmpty_throws() async {
        // Arrange
        let (repo, _) = makeSUT()
        URLProtocolStub.error = NSError(domain: "net", code: -2)

        // Act / Assert
        await XCTAssertThrowsErrorAsync(try await repo.getMovies())
    }

    // MARK: searchMovies(query:)

    func test_searchMovies_passesQuery_andReturnsResults() async throws {
        // Arrange
        let (repo, _) = makeSUT()
        let encoded = "bat%20man"
        let url = URL(string: "https://api.themoviedb.org/3/search/movie?api_key=e59fa91697a3e04422635ab8e092d648&language=en-US&query=\(encoded)&page=1&include_adult=false")!

        URLProtocolStub.set(url: url, json: [
            "results": [
                ["id": 99, "title": "Bat Man", "overview": "O", "poster_path": "p"]
            ]
        ])

        // Act
        let results = try await repo.searchMovies(query: "bat man")

        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, 99)
    }

    // MARK: getMovieDetail(movieId:)

    func test_getMovieDetail_networkSuccess_returnsDetail() async throws {
        // Arrange
        let (repo, _) = makeSUT()
        let mid = 21
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(mid)?api_key=e59fa91697a3e04422635ab8e092d648&language=en-US")!

        URLProtocolStub.set(url: url, json: [
            "id": mid,
            "title": "Blackjack",
            "overview": "O",
            "poster_path": NSNull(),
            "release_date": "2020-01-01",
            "runtime": 100,
            "genres": [["id": 1, "name": "Action"]],
            "vote_average": 7.2
        ])

        // Act
        let detail = try await repo.getMovieDetail(movieId: mid)

        // Assert
        XCTAssertEqual(detail.id, mid)
        XCTAssertEqual(detail.title, "Blackjack")
        XCTAssertEqual(detail.genres.first?.name, "Action")
    }

    func test_getMovieDetail_networkFails_noCache_throws() async {
        // Arrange
        let (repo, _) = makeSUT()
        URLProtocolStub.error = NSError(domain: "net", code: -3)

        // Act / Assert
        await XCTAssertThrowsErrorAsync(try await repo.getMovieDetail(movieId: 77))
    }
}
