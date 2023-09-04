//
//  FeedViewController+TestHelpers.swift
//  EssentialFeediOSTests
//
//  Created by Juan Carlos Merlos Albarracin on 28/8/23.
//

import UIKit
import EssentialFeediOS

// MARK: - DSL
extension FeedViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        return feedImageView(at: index) as? FeedImageCell
    }
    
    @discardableResult
    func simulateFeedImageViewNotVisible(at row: Int) -> FeedImageCell? {
        // Pirmero simulamos la view como visible
        let view = simulateFeedImageViewVisible(at: row)
        // Luego usamos el delegado de la tableView para notificar
        let delegate = tableView.delegate
        // Obtenemos el index path
        let index = IndexPath(row: row, section: feedImagesSection)
        
        // Notificamos con el método `didEndDisplaying` que se llama cuando se elimina una view de la table view
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)
        
        return view
    }
    
    func simulateFeedImageViewNearVisible(at row: Int) {
        // Utilizamos los datos capturados previamente de la table view
        let ds = tableView.prefetchDataSource
        // Creamos un index path
        let index = IndexPath(row: row, section: feedImagesSection)
        // Le decimos al data source de precarga, que precargue los datos que hay en el array de índices dado
        ds?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateFeedImageViewNotNearVisible(at row: Int) {
        simulateFeedImageViewNearVisible(at: row)
        
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        // Aquí le decimos al data source que cancele la precarga para cada fila dada
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
    }
    
    func renderedFeedImageData(at index: Int) -> Data? {
        return simulateFeedImageViewVisible(at: index)?.renderedImage
    }
    
    var errorMessage: String? {
        return errorView?.message
    }
    
    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
    
    func numberOfRenderedFeedImageViews() -> Int {
        return tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        // Obtener el data source de la table view
        let ds = tableView.dataSource
        // Crear un índice para la fila dada
        let index = IndexPath(row: row, section: feedImagesSection)
        // Pedir a data source la celda en ese índice
        return ds?.tableView(tableView, cellForRowAt: index)
    }
    
    private var feedImagesSection: Int {
        return 0
    }
}
