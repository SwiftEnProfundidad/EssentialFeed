//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 6/5/23.
//

import Foundation

// Somos el cliente y necesitamos una URLSession
public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    // Como no vamos a mockear `URLSession` le damos un valor
    // por defecto. No necesitamos mockear una `session`.
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // Error inesperado, no sabemos qué pasó
    private struct UnexpectedValuesRepresentation: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}
