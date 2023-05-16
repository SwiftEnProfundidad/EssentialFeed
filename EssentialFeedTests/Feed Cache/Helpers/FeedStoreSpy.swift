//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 11/5/23.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private (set) var receivedMessages = [ReceivedMessage]()
    
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private var retrievalCompletions = [RetrievalCompletion]()
    
    
    func deleteCachedFeed(completion: @escaping  DeletionCompletion) {
        // Capturamos el `completion`
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
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
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        retrievalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }
    
    // Completa la recuperación de cache con un error
    func completeRetrieval(with error: Error, at index: Int = 0) {
        // Obtenemos el `DeleteCompletion` en el índicenque nos pasan y
        // completamos con un `error. Es un closure que recibe un array
        retrievalCompletions[index](.failure(error))
    }
    
    // Completa la recuperación de cache sin valores
    func completeRetrievalWithEmptyCache(at index: Int = 0) {
        // Obtenemos el `DeleteCompletion` en el índicenque nos pasan y
        // completamos con un `error. Es un closure que recibe un array
        retrievalCompletions[index](.empty)
    }
    
    // Completa la recuperación de cache con datos
    func completeRetrieval(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
        // Obtenemos el `DeleteCompletion` en el índicenque nos pasan y
        // completamos con un `error. Es un closure que recibe un array
        retrievalCompletions[index](.found(feed: feed, tiemestamp: timestamp))
    }
}

