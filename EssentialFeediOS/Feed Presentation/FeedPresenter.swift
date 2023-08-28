//
//  FeedPresenter.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 24/8/23.
//

import Foundation
import EssentialFeed

// Separamos en dos protocolos, para no violar el principios de segregación de interfaces
// dado que la función `display(isLoading: Bool)` se lleva a cabo en `refreshControl` y la
// función `display(feed: [FeedImage])` se lleva a cabo en la `tableView`.
protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
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
    
    static var title: String {
        return NSLocalizedString("FEED_VIEW_TITLE",
                                 tableName: "Feed",
                                 bundle: Bundle(for: FeedPresenter.self),
                                 comment: "Title for the feed view")
    }
    
    func didStartLoadingFeed() {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async { [weak self] in self?.didStartLoadingFeed() }
        }
        
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async { [weak self] in self?.didFinishLoadingFeed(with: feed) }
        }
        
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display( FeedLoadingViewModel(isLoading: false))
    }
    
    func didFinishLoadingFeed(with error: Error) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async { [weak self] in self?.didFinishLoadingFeed(with: error) }
        }
        
        loadingView.display( FeedLoadingViewModel(isLoading: false))
    }
}
