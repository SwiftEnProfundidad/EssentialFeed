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
    
    override class func setUp() {
        // Necesitamos registrear `URLProtocolStub`
        URLProtocolStub.startInterceptingRequest()
    }
    
    override class func tearDown() {
        super.tearDown()
        
        // Una vez terminada la prueba tenemos que desregistrarla,
        // para no bloquear otras solicitudes de Test.
        URLProtocolStub.stopInterceptingRequest()
    }
    
    // Caso de uso de obtener la URL y realizar una solicitud GET con la URL.
    func test_getFromURL_performGETRequestWithURL() {
        let url = URL(string: "http://any-url.com")!
        let exp = expectation(description: "Wait for request")
        // Creamos un método para observar las request y
        // comparamos que la url y el httpMethod sea iguales
        // a los que los dados. Es decir, garantizamos la URL
        // y el método HTTP correctos en la solicitud GET
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        // Hacemos la solicitud desde una url dada.
        makeSUT().get(from: url) { _ in }
         
        wait(for: [exp], timeout: 1.0)
    }
    
    // Caso de uso en el que la URL falla en las solicitudes
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
                
        let exp = expectation(description: "Wait for complition")
        
        // Aquí queremos la respuesta con un error
        makeSUT().get(from: url) { result in
            switch result {
                case let .failure(receivedError as NSError):
                    XCTAssertEqual(receivedError.domain, error.domain)
                    XCTAssertEqual(receivedError.code, error.code)
                    XCTAssertNotNil(receivedError)
                default:
                    XCTFail("Expecte d failure with error \(error), got \(result) instead")
            }
            // Después de afirmar los valores podemos esperar la expectativa
            exp.fulfill()
        }
        
        // con un tiempo de espera
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    // Factory method: Movemos la creación de `URLSessionHTTPClient`
    // (el sistema bajo prueba, o SUT) a un método `Factory` para
    // proteger nuestra prueba de cambios importantes.
    private func makeSUT() -> URLSessionHTTPClient {
        return URLSessionHTTPClient()
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            // Removemos el stub interceptado al terminar
            stub = nil
            requestObserver = nil
        }
        
        // Podemos ver `canInit` se llama como método de clase,
        // por lo que todavía no tenemos una instancia. La `URL
        // LOADING SYSTEM` instanciará nuestro `URLProtocolStub`
        // solo si podemos manejar la solicitud.
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            // Interceptamos todas las solicitudes
            return true
        }
        
        // En este método comienza a cargar la request. El framework comienza a manejar la solicitud.
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
             return request
        }
        
        // Invocamos este método para decir que ahora
        // es el momento de que empice a cargar la URL
        override func startLoading() {
            // Comprobar si hay datos y si hay, se
            // los pasamos al `URL LOADING SYSTEM`
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            // Comprobamos si hay respuesta
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            // Comprobamos si hay un error
            if let error = URLProtocolStub.stub?.error {
                // `client`: El objeto que utiliza el protocolo para comunicarse con URL loading system.
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            // Tenemos que llamar al cliente y decirle que hemos
            // terminado de cargar y, completamos sin valores
            client?.urlProtocolDidFinishLoading(self)
        }
        
        // Aquí no hacemos nada, pero si no lo implementamos,
        // obtendremos un bloqueo en tiempo de ejecución.
        override func stopLoading() { }
    }
}

