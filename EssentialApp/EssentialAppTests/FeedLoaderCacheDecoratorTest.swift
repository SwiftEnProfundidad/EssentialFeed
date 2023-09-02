//
//  FeedLoaderCacheDecoratorTest.swift
//  EssentialAppTests
//
//  Created by Juan Carlos Merlos Albarracin on 2/9/23.
//

import XCTest
import EssentialFeed

final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: FeedLoader
    
    init(decoratee: FeedLoader) {
        self.decoratee = decoratee
    }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        // Para que pase ahora la prueba, necesitamos reenviar el mensaje `completion` al
        // `completion` del decorator para demostrar que mantenemos el mismo comportamiento de carga
        decoratee.load(completion: completion)
    }
}

class FeedLoaderCacheDecoratorTest: XCTestCase, FeedLoaderTestCase {
    
    func test_load_deliversFeedOnLoaderSucces() {
        let feed = uniqueFeed()
        let loader = FeedLoaderStub(result: .success(feed))
        let sut = FeedLoaderCacheDecorator(decoratee: loader)
        
        expect(sut, toCompleteWith: .success(feed))
    }
    
    func test_load_deliversErrordOnLoaderFailure() {
        let loader = FeedLoaderStub(result: .failure(anyNSError()))
        let sut = FeedLoaderCacheDecorator(decoratee: loader)
        
        expect(sut, toCompleteWith: .failure(anyNSError()))
    }
    
    // MARK: - Helpers
    
}
