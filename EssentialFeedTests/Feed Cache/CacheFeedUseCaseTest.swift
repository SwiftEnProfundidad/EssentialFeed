//
//  CacheFeddUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 8/5/23.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed() { [unowned self] error in
            if error == nil {
                self.store.insert(items)
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    
    private var deletionCompletions = [(Error?) -> Void]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deleteCachedFeedCallCount += 1
        // Capturamos el `completion`
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        // Obtenemos el `DeleteCompletion` en el índicenque nos pasan y
        // completamos con un `error. Es un closure que recibe un array
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        // Completamos sin ningún error, ya que fue exitoso el borrado
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem]) {
        insertCallCount += 1
    }
}

final class CacheFeedUseCaseTest: XCTestCase {
    
    // Caso de uso en el que no se elimina la memoria cache al crearla
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_ , store) = makeSUT()
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let items = [uniqueItems(), uniqueItems()]
        let (sut, store) = makeSUT()
        
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
    
    // Caso de uso en el que el guardado `save` solicita la
    // inserción en caché y se complete con un error de eliminación.
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items = [uniqueItems(), uniqueItems()]
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(items)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    // Caso de uso en el que solicitamos un nuevo guardado
    // en caché de los items con una eliminación exitosa
    func test_save_requestsNewCacheInsertionOnSuccessfulDeletion() {
        let items = [uniqueItems(), uniqueItems()]
        let (sut, store) = makeSUT()
        
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
    
    private func uniqueItems() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
