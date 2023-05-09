//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 6/5/23.
//

import XCTest

extension XCTestCase {
    // Método para fugas de memoria
    // Comprobamos que `instance` es nil, después de haber hecho capturas
    // con `self` en el código, que puede llevar a perdidas de memoria.
    // En la función `map` del tipo `RemoteFeedLoader` hacemos la función estática
    // con lo que no tenemos que llamar a `self` dentro del bloque `do-catch`, con
    // lo que evitamos el uso de `self` el ciclo de retención, con lo que se comprueba
    // que el siguiente bloque de código las instancias que recibe tienen valor `nil`
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
