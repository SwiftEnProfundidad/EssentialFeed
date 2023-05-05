//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 4/5/23.
//

import XCTest
import EssentialFeed

//// Creamos protocolos basados en mocking para burlarnos de la api de `URLSession`
////  y `URLSessionDataTask`. Esta la es la tercera forma para pruebas de network.
//
//// Lo que hacemos es hacer un protocolo que simule `URLSession` y para eso lo llamamos `HTTPSession`
//// Cambiamos `URL` --> `HTTP` y copiamos tal cual el método nativo de `URLSession`. El que implemente
//// este protocolo, ya no tendrá que sobreescribri (override) este método, solo tendrá que implementarlo,
//// ocultando así, todos los detalles internos sobre `URLSession`. Solo son abstracción para el testing.
//protocol HTTPSession {
//    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
//}
//
//// Hacemos lo mismo con `URLSessionDataTask` y la llamamos `HTTPSessionTask` y tiene el mismo
//// efecto que lo explicado en el protocolo anterior, pero solo copiamos el método `resume()`.
//// Sustituimos todas las `URLSession` por `HTTPSession` y todas las `URLSessionDataTask` por `HTTPSessionTask`
//protocol HTTPSessionTask {
//    func resume()
// }

class URLSessionHTTPClient {
    private let session: URLSession
    
    // Como no vamos a mockear `URLSession` le damos un valor por defecto
    // No necesitamos mockear una `session`.
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTest: XCTestCase {
    
    // Caso de uso en el que la URL falla en las solicitudes
    func test_getFromURL_failsOnRequestError() {
        // Necesitamos registrear `URLProtocolStub`
        URLProtocolStub.startInterceptingRequest()
        let url = URL(string: "http://any-url.com")!
        let requestError = NSError(domain: "any eror", code: 1)
        URLProtocolStub.stub(url: url, error: requestError)
        
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "Wait for complition")
        
        // Aquí queremos la respuesta con un error
        sut.get(from: url) { result in
            switch result {
                case let .failure(receivedError as NSError):
                    XCTAssertEqual(receivedError.domain, requestError.domain)
                    XCTAssertEqual(receivedError.code, requestError.code)
                    XCTAssertNotNil(receivedError)
                default:
                    XCTFail("Expecte d failure with error \(requestError), got \(result) instead")
            }
            // Después de afirmar los valores podemos esperar la expectativa
            exp.fulfill()
        }
        
        // con un tiempo de espera
        wait(for: [exp], timeout: 1.0)
        // Una vez terminada la prueba tenemos que desregistrarla,
        // para no bloquear otras solicitudes de Test.
        URLProtocolStub.stopInterceptingRequest()
    }
    
    // MARK: - Helpers
    
    private class URLProtocolStub: URLProtocol {
        // Necesitamos tener una colección de stubs
        // con una url que va a tener una tarea específica
        private static var stubs = [URL: Stub]()
        
        private struct Stub {
            let error: Error?
        }
        
        static func stub(url: URL, error: Error? = nil) {
            // El stub en una url dada, va a tener una task
            stubs[url] = Stub(error: error)
        }
        
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
        }
        
        // Podemos ver `canInit` se llama como método de clase,
        // por lo que todavía no tenemos una instancia. La `URL
        // LOADING SYSTEM` instanciará nuestro `URLProtocolStub`
        // solo si podemos manejar la solicitud
        override class func canInit(with request: URLRequest) -> Bool {
            // En este punto aún no tenemos una instancia de `URLProtocolStub`
            guard let url = request.url else { return false }
            
            return URLProtocolStub.stubs[url] != nil
        }
        
        // En este método comienza a cargar la request. El framework comienza a manejar la solicitud.
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
             return request
        }
        
        // Invocamos este método para decir que ahora
        // es el momento de que empice a cargar la URL
        override func startLoading() {
            // Si no hay un stub en la url dada, volvemos, no podemos hacer otra cosa.
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }
            
            // Comprobamos si hay un error
            if let error = stub.error {
                // `client`: El objeto que utiliza el protocolo para comunicarse con URL loading system.
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            // Tenemos que llamar al cliente y decirle que hemos terminado de cargar.
            client?.urlProtocolDidFinishLoading(self)
        }
        
        // Aquí no hacemos nada, pero si no lo implementamos,
        // obtendremos un bloqueo en tiempo de ejecución.
        override func stopLoading() { }
    }
}

