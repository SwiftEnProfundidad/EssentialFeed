//
//  LoadFeedFromCacheUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 11/5/23.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTest: XCTestCase {
    
    // Caso de uso en el que no se elimina la memoria caché al crearla
    // LocalFeedLoader no almacena mensajes en el momento de la creación
    // (antes de cargar el feed desde el almacenamiento en caché)
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    // Caso de uso en el que queremos probar el comando de carga (`load`). Cuando
    // cargamos, queremos solicitar una recuperación de de la caché desde el store
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    // Caso de uso en el que recibimos un error al solicitar una recuperación de caché
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(retrievalError), when: {
            store.completeRetrieval(with: retrievalError)
        })
    }
    
    // Caso de uso en el que el comando `load` no entrega `Images` con caché vacío
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut , store) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }
    
    // Caso de uso en el que verificamos la validación de caché
    func test_load_deliversCachedImagesOnNonExpireCache() {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        // Con esto cada vez que el código de producción solicite una fecha, devoleverá la fecha actual fija.
        let nonExpiredTimestamp = fixCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT { fixCurrentDate }
        
        expect(sut, toCompleteWith: .success(feed.models), when: {
            store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
        })
    }
    
    // Caso de uso en el que verificamos que la caché ha caducado
    func test_load_deliversNoImagesOnCacheExpiration() {
            let feed = uniqueImageFeed()
            let fixedCurrentDate = Date()
        // Con esto cada vez que el código de producción solicite una fecha, devoleverá la fecha actual fija.
            let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
            let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
            
        expect(sut, toCompleteWith: .success([]), when: {
                store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
            })
        }
    
    // Caso de uso en el que no entrega `Images` en cache de más de siete días de antigüedad
    func test_load_deliversNoImagesOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        // Con esto cada vez que el código de producción solicite una fecha, devoleverá la fecha actual fija.
        let expiredTimestamp = fixCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT { fixCurrentDate }
        
        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
        })
    }
    
    // Caso de uso en el que eliminamos la caché al recivir un error
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    // Caso de uso en el que `no` eliminamos la caché al recivir una caché vacía
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    // Caso de uso en el que `no` eliminamos la caché al ser la caché menor de siete días
    func test_load_hasNoSideEffectsOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        let nonExpiredTimestamp = fixCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT { fixCurrentDate }
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    // Caso de uso en el que `no` eliminamos la caché al ser la caché menor de siete días
    func test_load_hasNoSideEffectsOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        let expirationTimestamp = fixCurrentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT { fixCurrentDate }
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
        
    // Caso de uso en el que `no` eliminamos la caché al ser la caché menor de siete días
    func test_load_hasNoSideEffectsOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        let expiredTimestamp = fixCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT { fixCurrentDate }
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    // Caso de uso en el que la prueba de `load` no entrega `Result` después de que se haya desasignado la instancia `SUT`
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }

        sut = nil
        store.completeRetrievalWithEmptyCache()
        XCTAssertTrue(receivedResults.isEmpty)
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
    
    // Dado un `sut`, esperamos un `result` cuando ocurre una acción
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWith expectedResutl: LocalFeedLoader.LoadResult,
                        when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { recievedResult in
            switch (recievedResult, expectedResutl) {
                case let (.success(receivedImages), .success(expectedImages)):
                    XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
                    
                case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                    XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                    
                default:
                    XCTFail("Expected result \(expectedResutl), got \(recievedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        // En lugar de invocar un método directamente a la Store, invocamos la acción
        action()
        wait(for: [exp], timeout: 1.0)
    }
}
