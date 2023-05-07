//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Juan Carlos Merlos Albarracin on 7/5/23.
//

import XCTest
import EssentialFeed

final class EssentialFeedAPIEndToEndTests: XCTestCase {

    // Caso de uso para: probar servidor de prueba de extremo a extremo
    // Obtener FeedResutlt coincide con datos de cuenta de prueba fijos
    func test_endToEndTestServerGETFeedResutlt_matchesFixedTestAccountData() {
        // En este caso, la URL va a ser la que nos proporcionó backend
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url: testServerURL, client: client)
        
        // Ahora necesitamos cargar nuestro Feed y obtener el Result
        let exp = expectation(description: "Wait for load completion")
        
        // Capturamos el resultado
        var receivedResult: LoadFeedResult?
        loader.load { result in
            
        }
    }
}
