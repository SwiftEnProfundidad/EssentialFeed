//
//  FeedViewControllerTest.swift
//  EssentialFeediOSTests
//
//  Created by Juan Carlos Merlos Albarracin on 8/8/23.
//

import XCTest
import UIKit
import EssentialFeed

final class FeedViewController: UITableViewController {
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
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        refreshControl?.beginRefreshing()
        load()
    }
    
    @objc private func load() {
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
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
    
    // Caso de uso en el que actualizamos la vista varias veces mediante pull to refresh
    func test_userInitiatedFeedReload_reloadsFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadCallCount, 3)
    }
    
    // Caso de uso en el que primero cargamos los Feed's y aseguramos de tener un indicador de carga cuando se carga la view
    // Mostrar spinner en viewDidLoad
    func test_viewDidLoad_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertTrue(sut.isShowingLoadingIndicator)
    }
    
    // Caso de uso Ocultar spinner en viewDidLoad
    func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }
    
    // Caso de uso en el que al hacer pull to refresh, esperamos que RefreshControl se esté cargando
    func test_userInitiatedFeedReload_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        
        sut.simulateUserInitiatedFeedReload()
        
        XCTAssertTrue(sut.isShowingLoadingIndicator)
    }
    
    // Caso de uso en el que se oculta el spinner cuando la carga se ha completado
    func test_unserInitiatedFeedReload_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator)
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
        private var completions = [(FeedLoader.Result) -> Void]()
        
        var loadCallCount: Int {
            return completions.count
        }

        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func completeFeedLoading() {
            completions[0](.success([]))
        }
    }
}

private extension FeedViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}


