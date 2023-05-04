//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 4/5/23.
//

import XCTest

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in }
    }
}

final class URLSessionHTTPClientTest: XCTestCase {
    // Caso de uso solicitar la URL
    func test() {
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        // Creamos una inyección de dependenci en el constructor, que será código par producción.
        // Todo esto que estamos construyendo con TDD, irá a parar a código de producción.
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        
        // La URLSession aún no ha recibido url, porque es un detalle de prueba,
        // es un `Spy`, por lo que vamos a crear nuestra propia `URLSessionSpy`
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    // MARK: - Helpers
    
    private class URLSessionSpy: URLSession {
        var receivedURLs = [URL]()
        
        // Sobreescribimos esta función que se llamará en el método `get` ya que la clase que lo contien hereda de `URLSession`
        // y la clase `URLSessionHTTPClient` inyecta un `URLSessión` el cual recibe una `session` que es una instancia
        // de `URLSessionSpy` la cual también hereda de `URLSessión`, con lo que llamará a este método sobreescrito que devuelve
        // una `URLSessionDataTask` mockeada con la clase `FakeURLSessionDataTask` la cual evita las solicitudes a una `Network`
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            // El metodo devueve un `URLSessionDataTask` pero no queremos tener una solicitud de Network en
            // los test, por lo que tenemos que crear algún tipo de implementación mock para `URLSessionDataTask`
            // `return URLSession.shared.dataTask(with: url, completionHandler: completionHandler)`
            return FakeURLSessionDataTask()
        }
    }
    
    // Mock para evitar devolver un `URLSessionDataTask`
    private class FakeURLSessionDataTask: URLSessionDataTask { }
}
