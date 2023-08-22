//
//  FeedViewModel.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 22/8/23.
//

import Foundation
import EssentialFeed

final class FeedViewModel {
    typealias Observer<T> = (T) -> Void
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    // Mantenemos el estado transitorio
    // var onChange: ((FeedViewModel) -> Void)?
    
    // No hace falta mantener el estado
    var onLoadingStateChange: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?
    
    // Mantenemos el estado transitorio
    //    private(set) var isLoading: Bool = false {
    //        didSet { onChange?(self) }
    //    }
    
    func loadFeed() {
        onLoadingStateChange?(true)
        // isLoading = true
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            // Mantenemos el estado transitorio
            // self?.isLoading = false
            
            // No hace falta mantener el estado
            self?.onLoadingStateChange?(false)
        }
    }
}
