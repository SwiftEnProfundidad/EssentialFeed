//
//  FeedViewControllerTest.swift
//  EssentialFeediOSTests
//
//  Created by Juan Carlos Merlos Albarracin on 8/8/23.
//

import XCTest
import UIKit

final class FeedViewController: UIViewController {
    private var loader: FeedViewControllerTest.LoaderSpy?
    // Hacemos que nuestro init sea de conveniencia, dado que no
    // necesitamos un inicializador personalizado, por lo que no
    // necestiamos implementar el inicializado requerido de UIViewController
    convenience init(loader: FeedViewControllerTest.LoaderSpy) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader?.load()
    }
}

final class FeedViewControllerTest: XCTestCase {
    
    // Caso de uso en el que aún no se ha cargado nada
    func test_init_doesNotLoaderFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    // Caso de uso en el que cargamos los Feed's una vez que se cargue la view
    func test_viewDidLoad_loadsFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    // MARK: - Helpers
    
    class LoaderSpy {
        private(set) var loadCallCount: Int = 0
        
        func load() {
            loadCallCount += 1
        }
    }
}


