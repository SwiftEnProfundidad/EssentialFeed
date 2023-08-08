//
//  FeedViewControllerTest.swift
//  EssentialFeediOSTests
//
//  Created by Juan Carlos Merlos Albarracin on 8/8/23.
//

import XCTest
import UIKit
import EssentialFeed

final class FeedViewController: UIViewController {
    private var loader: FeedLoader?
    // Hacemos que nuestro init sea de conveniencia, dado que no
    // necesitamos un inicializador personalizado, por lo que no
    // necesitamos implementar el inicializado requerido de UIViewController
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader?.load { _ in }
    }
}

final class FeedViewControllerTest: XCTestCase {
    
    // Caso de uso en el que aún no se ha cargado nada
    func test_init_doesNotLoaderFeed() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    // Caso de uso en el que cargamos los Feed's una vez que se cargue la view
    func test_viewDidLoad_loadsFeed() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    // MARK: - Helpers
    
    /// Method Factory
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, client: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    class LoaderSpy: FeedLoader {
        private(set) var loadCallCount: Int = 0

        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            loadCallCount += 1
        }
        
    }
}


