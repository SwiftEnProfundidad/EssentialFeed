//
//  FeedPresenter.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 24/8/23.
//

import EssentialFeed

// Separamos en dos protocolos, para no violar el principios de segregación de interfaces
// dado que la función `display(isLoading: Bool)` se lleva a cabo en `refreshControl` y la
// función `display(feed: [FeedImage])` se llev a cabo en la `tableView`.
protocol FeedLoadingView: AnyObject {
    func display(isLoading: Bool)
}

protocol FeedView {
    func display(feed: [FeedImage])
}

final class FeedPresenter {
    typealias Observer<T> = (T) -> Void
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    var feedView: FeedView?
    weak var loadingView: FeedLoadingView?
    
    func loadFeed() {
        loadingView?.display(isLoading: true)
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.feedView?.display(feed: feed)
            }
            self?.loadingView?.display(isLoading: false)
        }
    }
}
