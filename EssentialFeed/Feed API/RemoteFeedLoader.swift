//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 30/4/23.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result<[FeedItem], Error>) -> Void) {
        client.get(from: url) { [weak self] result in
            // Grantizamos que se entregará un resultado, succes o failure,
            // si la instancia está asignada, es decir, self no es nil, de
            // lo contrario volvemos para no tener ciclos de retención de memoria.
            guard self != nil else { return }
            
            switch result {
                case let .success(data, response):
                    completion(FeedItemsMapper.map(data, from: response))
                case .failure:
                    completion(.failure(.connectivity))
            }
        }
    }
}


