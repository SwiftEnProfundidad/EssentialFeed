//
//  RemoteWithLocalFallbackFeedLoaderTest.swift
//  EssentialAppTests
//
//  Created by Juan Carlos Merlos Albarracin on 31/8/23.
//

import XCTest
import EssentialFeed
import EssentialApp

class FeedLoaderWithFallbackCompositeTest: XCTestCase, FeedLoaderTestCase {
    
    func test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess() {
        let primaryFeed = uniqueFeed()
        let fallbackFeed = uniqueFeed()
        // Instanciamos nuestro `sut`, que debe comenzar con un`primaryLoader` y un `fallbackLoader`
        let sut = makeSUT(primaryResult: .success(primaryFeed), fallbackResult: .success(fallbackFeed))
        
        expect(sut, toCompleteWith: .success(primaryFeed))
    }
    
    func test_load_deliversFallbackFeedOnPrimaryLoaderFailure() {
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .success(fallbackFeed))
        
        expect(sut, toCompleteWith: .success(fallbackFeed))
    }
    
    func test_load_deliversErrorOnBothPrimaryAndFallbackLoaderFailure() {
        let sut = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .failure(anyNSError()))
        
        expect(sut, toCompleteWith: .failure(anyNSError()))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(primaryResult: FeedLoader.Result, fallbackResult: FeedLoader.Result, file: StaticString = #file, line: UInt = #line) -> FeedLoader {
        // Con este `Stub` (`LoaderStub`), protegemos esta prueba de futuros cambios.
        // Estamos testeando `RemoteWithLocalFallbackFeedLoader` de forma aislada.
        let primaryLoader = FeedLoaderStub(result: primaryResult)
        let fallbackLoader = FeedLoaderStub(result: fallbackResult)
        let sut = FeedLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}

// NOTA: Con un ´Stub` establecemos los valores por adelantado y con
// un `Spy` capturamos los valores para que podamos usarlos más tarde
// Los `Stub` son más simples, pero menos precisos sobre los que sucede
// durante los test, por eso son más flexibles. Son buenos, cuando
// tenemos un caso de uso simple.
