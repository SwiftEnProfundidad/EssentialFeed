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
    
    struct UnexpectedValuesRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                // En este caso no verificamos el error, dado que los tres valores son nil.
                completion(.failure(UnexpectedValuesRepresentation()))
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
        let url = anyURL()
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
    
    // Caso de uso en el que esperamos que el error recibido sea el mismo que el error de la solicitud
    func test_getFromURL_failsOnRequestError() {
        let requestError = NSError(domain: "any error", code: 1)
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        
        XCTAssertEqual(receivedError?._domain, requestError._domain)
        XCTAssertEqual(receivedError?._code, requestError._code)
        XCTAssertNotNil(receivedError)
    }
    
    // Caso de uso en el que falla en todos los valores: data, urlResponse, Error (todos nil)
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        let anyData = Data("any data".utf8)
        let anyError = NSError(domain: "any error", code: 0)
        let nonHTTPURLResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyHTTPURLResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
          
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: anyError))
    }
    
    
    // MARK: - Helpers
    
    // Factory method: Movemos la creación de `URLSessionHTTPClient`
    // (el sistema bajo prueba, o SUT) a un método `Factory` para
    // proteger nuestra prueba de cambios importantes.
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for complition")
        
        var receivedError: Error?
        // Aquí queremos la respuesta con un error
        sut.get(from: anyURL()) { result in
            switch result {
                case let .failure(error):
                    receivedError = error
                    // Todos son nil, no hay manera de manejar o recuperarse de este error
                default:
                    XCTFail("Expecte failure, got \(result) instead", file:  file, line: line)
            }
            // Después de afirmar los valores podemos esperar la expectativa
            exp.fulfill()
        }
        
        // con un tiempo de espera
        wait(for: [exp], timeout: 1.0)
        
        return receivedError
    }
    
    private func anyURL() -> URL {
            return URL(string: "http://any-url.com")!
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

