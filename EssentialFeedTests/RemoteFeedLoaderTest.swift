//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 29/4/23.
//

import XCTest

/// Creamos el nuesto tipo Remoto para `RemoteFeedLoaderTest`
class RemoteFeedLoader {
    
}

class HTTPClient {
    var requestedURL: URL?
}

final class RemoteFeedLoaderTest: XCTestCase {

    // Hacemos el mínimo test para el inicializador
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }
}
