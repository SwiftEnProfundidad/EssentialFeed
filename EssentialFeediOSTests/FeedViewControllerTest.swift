//
//  FeedViewControllerTest.swift
//  EssentialFeediOSTests
//
//  Created by Juan Carlos Merlos Albarracin on 8/8/23.
//

import XCTest

final class FeedViewController {
    init(loader: FeedViewControllerTest.LoaderSpy) {
        
    }
}

final class FeedViewControllerTest: XCTestCase {
    
    func test_init_doesNotLoaderFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    // MARK: - Helpers
    
    class LoaderSpy {
        private(set) var loadCallCount: Int = 0
    }
}


