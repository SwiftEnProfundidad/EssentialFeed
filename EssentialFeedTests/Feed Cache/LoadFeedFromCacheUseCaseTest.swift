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
        
        expect(sut, toCompletionWith: .failure(retrievalError), when: {
            store.completeRetrieval(with: retrievalError)
        })
    }
    
    // Caso de uso en el que el comando `load` no entrega `Images` con caché vacío
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut , store) = makeSUT()
        
        expect(sut, toCompletionWith: .success([]), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }
    
    // Caso de uso en el que verificamos la validación de caché
    func test_load_deliversCachedImageOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        // Con esto cada vez que el código de producción solicite una fecha, devoleverá la fecha actual fija.
        let lessThanSevenDaysOldTimestamp = fixCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT { fixCurrentDate }
        
        expect(sut, toCompletionWith: .success(feed.models), when: {
            store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        })
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
                        toCompletionWith expectedResutl: LocalFeedLoader.LoadResult,
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
    
    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    // Factory
    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let models = [uniqueImage(), uniqueImage()]
        let local = models.map { LocalFeedImage(
            id: $0.id,
            description: $0.description,
            location: $0.location,
            url: $0.url) }
        
        return (models, local)
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

private extension Date {
    // Creamos nuestro DSL para las fechas
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
