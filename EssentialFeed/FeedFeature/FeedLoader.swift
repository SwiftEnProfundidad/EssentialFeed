//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 29/4/23.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedImage], RemoteFeedLoader.Error>

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
