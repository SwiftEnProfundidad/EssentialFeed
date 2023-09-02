//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 17/5/23.
//

import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
}

// Factory
 func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let local = models.map { LocalFeedImage(
        id: $0.id,
        description: $0.description,
        location: $0.location,
        url: $0.url) }
    
    return (models, local)
}

// Creamos nuestro DSL (Domain Specific Language) para cache-policy
extension Date {
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
    
    private func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

// Reusable DSL helper
extension Date {
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
