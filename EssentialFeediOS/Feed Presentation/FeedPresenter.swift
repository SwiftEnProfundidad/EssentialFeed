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
    private let feedView: FeedView
    private let loadingView: FeedLoadingView
    
    init(feedView: FeedView, loadingView: FeedLoadingView) {
        self.feedView = feedView
        self.loadingView = loadingView
    }
    
    func didStartLoadingFeed() {
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display( FeedLoadingViewModel(isLoading: false))
    }
    
    func didFinishLoadingFeed(with error: Error) {
        loadingView.display( FeedLoadingViewModel(isLoading: false))
    }
}
