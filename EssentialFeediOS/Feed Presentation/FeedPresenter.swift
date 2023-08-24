//
//  FeedPresenter.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 24/8/23.
//

import EssentialFeed

struct FeedLoadingViewModel {
    let isLoading: Bool
}

// Separamos en dos protocolos, para no violar el principios de segregación de interfaces
// dado que la función `display(isLoading: Bool)` se lleva a cabo en `refreshControl` y la
// función `display(feed: [FeedImage])` se llev a cabo en la `tableView`.
protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

struct FeedViewModel {
    let feed: [FeedImage]
}

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

final class FeedPresenter {
    typealias Observer<T> = (T) -> Void
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    var feedView: FeedView?
    var loadingView: FeedLoadingView?
    
    func loadFeed() {
        loadingView?.display(FeedLoadingViewModel(isLoading: true))
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.feedView?.display(FeedViewModel(feed: feed))
            }
            self?.loadingView?.display(FeedLoadingViewModel(isLoading: false))
        }
    }
}
