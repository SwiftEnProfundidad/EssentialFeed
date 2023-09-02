//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 3/5/23.
//

import Foundation

final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    // La hacemos `static` ya que no necesitamos una instancia o llamar a `self` para acceder a
    // `FeedItemsMap`. De ahí que los test pasen, al comprobar que tanto `sut` como `client` son
    // `nil` una vez se ha llevado el testeo de éstas (en `addTeardownBlock` de los test).
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.isOK, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }

        return root.items
    }
}
