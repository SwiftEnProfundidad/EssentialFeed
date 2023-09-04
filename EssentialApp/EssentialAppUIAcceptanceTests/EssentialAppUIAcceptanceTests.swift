//
//  EssentialAppUIAcceptanceTests.swift
//  EssentialAppUIAcceptanceTests
//
//  Created by Juan Carlos Merlos Albarracin on 3/9/23.
//

import XCTest

//final class EssentialAppUIAcceptanceTests: XCTestCase {
//    
//    // Primero prpbamos los criterios de aceptación.
//    // En el lanzamiento, debe mostrar RemoteFeed cuando el cliente tiene conectividad
//    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
//        let app = XCUIApplication()
//        app.launchArguments = ["-reset", "-connectivity", "online"]
//        app.launch()
//        
//        let feedCells = app.cells.matching(identifier: "feed-image-cell")
//        // Si cargamos las 22 imágenes que nos vienen en el json remoto,
//        // tienen que aparecer 22 celdas, solo probamos el cell count y
//        // no que se carguen correctamente las imágenes en cada celda.
//        XCTAssertEqual(feedCells.count, 2)
//        // Aquí nos aseguramos de que por lo menos se carga una imagen en la celda
//        // que se muestra en pantalla, con lo que verificamos que se cargan
//        // las imágenes en las celdas que aúno no están visibles en pantalla.
//        let firstImage = app.images.matching(identifier: "feed-image-view").firstMatch
//        XCTAssertTrue(firstImage.exists)
//    }
//    
//    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
//        let onlineApp = XCUIApplication()
//        onlineApp.launchArguments = ["-reset", "-connectivity", "online"]
//        onlineApp.launch()
//        
//        let offlineApp = XCUIApplication()
//        // Como no podemos hacer que la app tenga conectividad o no
//        // pasamos argumentos de conectividad con el valor fuera de línea
//        offlineApp.launchArguments = ["-connectivity", "offline"]
//        offlineApp.launch()
//        
//        // Cuando no tenemos conectividad mostramos un `CachedFeed` y un `CachedImage`
//        let cachedFeedCells = offlineApp.cells.matching(identifier: "feed-image-cell")
//        XCTAssertEqual(cachedFeedCells.count, 2)
//        
//        let firstCachedImage = offlineApp.images.matching(identifier: "feed-image-view").firstMatch
//        XCTAssertTrue(firstCachedImage.exists)
//    }
//    
//    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
//        let app = XCUIApplication()
//        // Con el parámetro `-reset` nos aseguramos que no tengamos caché, dado que
//        // las pruebas anteriores, crean una caché, con lo que la prueba no pasaría
//        app.launchArguments = ["-reset", "-connectivity", "offline"]
//        app.launch()
//        
//        let feedCells = app.cells.matching(identifier: "feed-image-cell")
//        XCTAssertEqual(feedCells.count, 0)
//    }
//    
//}


class EssentialAppUIAcceptanceTests: XCTestCase {
    
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let app = XCUIApplication()
        app.launchArguments = ["-reset", "-connectivity", "online"]
        app.launch()
        
        let feedCells = app.cells.matching(identifier: "feed-image-cell")
        XCTAssertEqual(feedCells.count, 2)
        
        let firstImage = app.images.matching(identifier: "feed-image-view").firstMatch
        XCTAssertTrue(firstImage.exists)
    }
    
    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
        let onlineApp = XCUIApplication()
        onlineApp.launchArguments = ["-reset", "-connectivity", "online"]
        onlineApp.launch()

        let offlineApp = XCUIApplication()
        offlineApp.launchArguments = ["-connectivity", "offline"]
        offlineApp.launch()

        let cachedFeedCells = offlineApp.cells.matching(identifier: "feed-image-cell")
        XCTAssertEqual(cachedFeedCells.count, 2)
        
        let firstCachedImage = offlineApp.images.matching(identifier: "feed-image-view").firstMatch
        XCTAssertTrue(firstCachedImage.exists)
    }
    
    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
        let app = XCUIApplication()
        app.launchArguments = ["-reset", "-connectivity", "offline"]
        app.launch()

        let feedCells = app.cells.matching(identifier: "feed-image-cell")
        XCTAssertEqual(feedCells.count, 0)
    }
    
}
