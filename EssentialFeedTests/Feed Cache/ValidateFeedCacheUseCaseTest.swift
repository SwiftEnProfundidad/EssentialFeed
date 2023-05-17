//
//  ValidateFeedCacheUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 16/5/23.
//

import XCTest
import EssentialFeed

final class ValidateFeedCacheUseCaseTest: XCTestCase {

    // Caso de uso en el que `LocalFeedLoader` no almacena mensajes en el
    // momento de la creación (antes de validar el feed almacenado en caché)
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    // Caso de uso en el que eliminamos la caché al recivir un error
    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.validateCache() 
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    // Caso de uso en el que `no` eliminamos la caché al recivir una caché vacía
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    // Caso de uso en el que `no` eliminamos la caché al ser la caché menor de siete días
    func test_validateCache_doesNotDeleteLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT { fixCurrentDate }
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()
        
        sut = nil
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    // MARK: - Helpers
    
    /// Method Factory
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
}
