//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 29/4/23.
//

import XCTest
/// CÓDIGO DE PRODUCCIÓN

/// Creamos el nuesto tipo Remoto para `RemoteFeedLoaderTest`
class RemoteFeedLoader {
    let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load() {
        client.get(from: URL(string: "https://a-url.com")!)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

/// CÓDIGO DE TESTEO
class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
     func get(from url: URL) {
        requestedURL = url
    }
}

final class RemoteFeedLoaderTest: XCTestCase {
    
    // Hacemos el mínimo test para el inicializador del caso de uso
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(client: client)
        
        XCTAssertNil(client.requestedURL)
    }
    
    // Ahora el test para la carga de FeedItems del caso de uso
    func test_load_requestDataFromURL() {
        // Ahora sí tenemos un cliente, ya que traemos datos
        /// Arrange: `Given`, dado un cliente y un sut
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client)
        
        /// Act: `When` Cuando invocamos `sut.load()`
        sut.load()
        
        /// Assert: `Then` entonces afirmamos que una
        /// request URL fue iniciada en el `client`
        XCTAssertNotNil(client.requestedURL)
    }
}
