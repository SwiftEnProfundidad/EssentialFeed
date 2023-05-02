//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 29/4/23.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageUTL: URL
}
