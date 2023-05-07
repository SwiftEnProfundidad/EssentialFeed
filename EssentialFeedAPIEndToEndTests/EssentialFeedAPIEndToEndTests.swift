//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Juan Carlos Merlos Albarracin on 7/5/23.
//

import XCTest
import EssentialFeed

// NOTA: es bueno tener este TestCase esté aislado porque no queremos tener que
// ejecutarlo todo el tiempo con nuestra unidad de Test, tardar alrededor de 5 seg.
final class EssentialFeedAPIEndToEndTests: XCTestCase {
    
    // Caso de uso para: probar servidor de prueba de extremo a extremo
    // Obtener FeedResutlt coincide con datos de cuenta de prueba fijos
    func test_endToEndTestServerGETFeedResutlt_matchesFixedTestAccountData() {
        switch getFeedResult() {
            case let .success(items):
                XCTAssertEqual(items.count, 8, "Expected 8 items in the test accoount feedd")
                XCTAssertEqual(items[0], expectedItem(at: 0))
                XCTAssertEqual(items[1], expectedItem(at: 1))
                XCTAssertEqual(items[2], expectedItem(at: 2))
                XCTAssertEqual(items[3], expectedItem(at: 3))
                XCTAssertEqual(items[4], expectedItem(at: 4))
                XCTAssertEqual(items[5], expectedItem(at: 5))
                XCTAssertEqual(items[6], expectedItem(at: 6))
                XCTAssertEqual(items[7], expectedItem(at: 7))
                
            case let .failure(error):
                XCTFail("Expected succesful feed resutl, got \(error) instead")
            default:
                XCTFail("Expected successful feed result, got no result instead")
        }
    }
    
    // MARK: - Helpers
    
    private func getFeedResult() -> LoadFeedResult? {
        // En este caso, la URL va a ser la que nos proporcionó backend
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url: testServerURL, client: client)
        
        // Ahora necesitamos cargar nuestro Feed y obtener el Result
        let exp = expectation(description: "Wait for load completion")
        
        // Capturamos el resultado
        var receivedResult: LoadFeedResult?
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
        return receivedResult
    }
    
    private func expectedItem(at index: Int) -> FeedItem {
        return FeedItem(
            id: id(at: index),
            description: description(at: index),
            location: location(at: index),
            imageURL: imageURL(at: index))
    }
    
    private func id(at index: Int) -> UUID {
        return UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ][index])!
    }
    
    private func description(at index: Int) -> String? {
        return [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8"
        ][index]
    }
    
    private func location(at index: Int) -> String? {
        return [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8"
        ][index]
    }
    
    private func imageURL(at index: Int) -> URL {
        return URL(string: "https://url-\(index+1).com")!
    }
}
