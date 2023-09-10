//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 10/5/23.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
 
