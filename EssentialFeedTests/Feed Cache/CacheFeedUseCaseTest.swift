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
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed() { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    // Un array de tuplas
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    
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
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        insertCallCount += 1
        // Cada vez que se invoca este méto
        // insertamos los items y la timestamp
        insertions.append((items, timestamp))
    }
}

final class CacheFeedUseCaseTest: XCTestCase {
    
    // Caso de uso en el que no se elimina la memoria cache al crearla
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_ , store) = makeSUT()
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    // Caso de uso en el que al guardar borramos la cache con éxito
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
    
    // Caso de uso en el que guarda las solicitudes de una nueva
    // inserción en caché con timestamp con una eliminación exitosa.
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItems(), uniqueItems()]
        // La fecha/hora actual no es una función pura (cada vez que crea una instancia de fecha,
        // tiene valores diferentes: la fecha/hora actual)
        
        // En lugar de permitir que el caso de uso produzca la fecha actual a través de la función
        // impura `Date.init()` directamente, podemos trasladar esta responsabilidad a un colaborador
        // (un cierre simple en este caso) e inyectarla como una dependencia. Luego, podemos controlar
        // fácilmente la fecha/hora actual durante la prueba.
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.items, items)
        XCTAssertEqual(store.insertions.first?.timestamp, timestamp)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
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
