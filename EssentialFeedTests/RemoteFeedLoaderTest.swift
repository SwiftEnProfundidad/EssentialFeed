//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 29/4/23.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTest: XCTestCase {
    
    // Hacemos el mínimo test para el inicializador del caso de uso
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // Ahora el test para la carga de FeedItems del caso de uso
    func test_load_requestsDataFromURL() {
        // Ahora sí tenemos un cliente, ya que traemos datos
        /// Arrange: `Given`, dado un cliente y un sut
        let url = URL(string: "https://a.given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        /// Act: `When` Cuando invocamos `sut.load()`
        sut.load()
        
        /// Assert: `Then` entonces afirmamos que una
        /// request URL fue iniciada en el `client`
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a.given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func text_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        var captureErrors = [RemoteFeedLoader.Error]()
        sut.load { captureErrors.append($0) }
        
        let clientError = NSError(domain: "Test", code: 0)
        client.completions[0](clientError)

        
        XCTAssertEqual(captureErrors, [.connectivity])
    }
    
    // MARK: - Helpers - CÓDIGO DE TESTEO
    
    /// Method factory
    private func makeSUT(url: URL = URL(string: "https://a.given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        var completions = [(Error) -> Void]()
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            completions.append(completion)
            requestedURLs.append(url)
        }
    }
}
