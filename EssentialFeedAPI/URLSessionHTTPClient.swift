//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 6/5/23.
//

import Foundation

// Somos el cliente y necesitamos una URLSession
public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    // Como no vamos a mockear `URLSession` le damos un valor
    // por defecto. No necesitamos mockear una `session`.
    // URLSession = .shared ( se hizo anterioremente)
    public init(session: URLSession) {
        self.session = session
    }
    
    // Error inesperado, no sabemos qué pasó
    private struct UnexpectedValuesRepresentation: Error {}
    
    private struct URLSessionTaskWrapper: HTTPClientTask {
        let wrapped: URLSessionTask
        
        func cancel() {
            wrapped.cancel()
        }
    }
    
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        let task = session.dataTask(with: url) { data, response, error in
            completion(Result {
                if let error = error {
                    throw error
                } else if let data = data, let response = response as? HTTPURLResponse {
                    return (data, response)
                } else {
                    throw UnexpectedValuesRepresentation()
                }
            })
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
}
