//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 18/8/23.
//

import UIKit
import EssentialFeed

final public class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private var refreshController: FeedRefreshViewController?
    private var imageLoader: FeedImageDataLoader?
    private var tableModel = [FeedImage]() {
        didSet { tableView.reloadData() }
    }
    private var cellControllers = [IndexPath: FeedImageCellController]()
    
    public convenience init(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) {
        self.init()
        self.refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        self.imageLoader = imageLoader
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = refreshController?.view
        refreshController?.onRefresh = { [weak self] feed in
            self?.tableModel = feed
        }
        tableView.prefetchDataSource = self
        refreshController?.refresh()
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = tableModel[indexPath.row]
        let cellController = FeedImageCellController(model: cellModel, imageLoader: imageLoader!)
        // Mantenemos el estado de la tarea
        cellControllers[indexPath] = cellController
        return cellController.view()
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        removeCellController(forRowAt: indexPath)
        cellControllers[indexPath] = nil
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Para cada indexPath dado
        indexPaths.forEach { indexPath in
            // Invocamos el método `preload()` para activar una precarga de image
            cellController(forRowAt: indexPath).preload()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(removeCellController)
    }
    
    private func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        // Obtenemos el `cellModel`
        let cellModel = tableModel[indexPath.row]
        // Y le decimos al loader, que cargue la imagen y mantenemos el estado en la precarga para las filas
        let cellController = FeedImageCellController(model: cellModel, imageLoader: imageLoader!)
        // Mantenemos el estado de la tarea
        cellControllers[indexPath] = cellController
        return cellController
    }
    
    private func removeCellController(forRowAt indexPath: IndexPath) {
        // Detenmos la tarea y libera memoria
        cellControllers[indexPath] = nil
    }
}
