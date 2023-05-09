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
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed() { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

class FeedStore {
    typealias deletionCompletion = (Error?) -> Void
    typealias insertionCompletion = (Error?) -> Void
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFedd
        case insert([FeedItem], Date)
    }
    
    private (set) var receivedMessages = [ReceivedMessage]()
    
    private var deletionCompletions = [deletionCompletion]()
    private var insertionCompletions = [insertionCompletion]()
    
    func deleteCachedFeed(completion: @escaping deletionCompletion) {
        // Capturamos el `completion`
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFedd)
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
    
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping insertionCompletion) {
        // Cada vez que se invoca a este método, insertamos el bloque
        // `completion` a nuestro array de `insertCompletions` capturados
        insertionCompletions.append(completion)
        // Cada vez que se invoca este método
        // insertamos los items y la timestamp
        receivedMessages.append(.insert(items, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        // Obtenemos el `DeleteCompletion` en el índicenque nos pasan y
        // completamos con un `error. Es un closure que recibe un array
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)

    }
}

final class CacheFeedUseCaseTest: XCTestCase {
    
    // Caso de uso en el que no se elimina la memoria cache al crearla
    func test_init_doesNotMessageStoreUponCreation() {
        let (_ , store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    // Caso de uso en el que al guardar borramos la cache con éxito
    func test_save_requestsCacheDeletion() {
        let items = [uniqueItems(), uniqueItems()]
        let (sut, store) = makeSUT()
        
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFedd])
    }
    
    // Caso de uso en el que el guardado `save` solicita la
    // inserción en caché y se complete con un error de eliminación.
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items = [uniqueItems(), uniqueItems()]
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(items) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFedd])
    }
    
    // Caso de uso en el que se solicita una nueva inserción
    // en caché con timestamp con una eliminación exitosa.
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
        
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFedd, .insert(items, timestamp)])
    }
    
    // Caso de uso en el que un error en la elimanación, el sistema entrega un error
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        expect(sut, toCompleteWithError: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
    }
    
    // Caso de uso en el que un error en la inserción, el sistema entrega un error
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWithError: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }
    
    // Caso de uso en el que la eleminación y la inserción fue exitosa entregamos mensaje de éxito
    func test_save_succeedsOnSuccessfulInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithError: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
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
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWithError expectedError: NSError?,
                        when action: () -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let exp = expectation(description: "Wait for save completion")
        
        var receivedError: Error?
        sut.save([uniqueItems()]) { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
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