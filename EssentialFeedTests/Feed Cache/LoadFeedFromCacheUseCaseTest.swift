//
//  LoadFeedFromCacheUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 11/5/23.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTest: XCTestCase {
    
    // Caso de uso en el que no se elimina la memoria cache al crearla
    func test_init_doesNotMessageStoreUponCreation() {
        let (_ , store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
    private class FeedStoreSpy: FeedStore {
        
        enum ReceivedMessage: Equatable {
            case deleteCachedFedd
            case insert([LocalFeedImage], Date)
        }
        
        private (set) var receivedMessages = [ReceivedMessage]()
        
        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()
        
        func deleteCachedFeed(completion: @escaping  DeletionCompletion) {
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
        
        func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            // Cada vez que se invoca a este método, insertamos el bloque
            // `completion` a nuestro array de `insertCompletions` capturados
            insertionCompletions.append(completion)
            // Cada vez que se invoca este método
            // insertamos los items y la timestamp
            receivedMessages.append(.insert(feed, timestamp))
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
}
