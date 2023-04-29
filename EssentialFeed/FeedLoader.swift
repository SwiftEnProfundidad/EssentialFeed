//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 29/4/23.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader{
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
