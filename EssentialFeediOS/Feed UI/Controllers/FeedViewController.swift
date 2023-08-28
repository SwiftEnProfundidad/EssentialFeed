//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 18/8/23.
//

import UIKit

protocol FeedViewControllerDelegate {
    func didRequestFeedRefresh()
}

final public class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching, FeedLoadingView {
    var delegate: FeedViewControllerDelegate?
    
    var tableModel = [FeedImageCellController]() {
        didSet {
            // Comprobamos primero si está en el hilo principal
            // ya que todas las operaciones no actúan en background
            // como por ejemplo, si venimos de caché, algo muy rápido
            if Thread.isMainThread {
                tableView.reloadData()
                // De lo contrario, despachamos de forma asíncrona a `MainQueue`
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
    }
    
    @IBAction private func refresh() {
        delegate?.didRequestFeedRefresh()
    }
    
    func display(_ viewModel: FeedLoadingViewModel) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async { [weak self] in self?.display(viewModel) }
        }
        if viewModel.isLoading {
            refreshControl?.beginRefreshing()
        } else {
            refreshControl?.endRefreshing()
        }
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Llamamos a la view que configura la celda en el indexPath dado
        return cellController(forRowAt: indexPath).view(in: tableView)
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelCellControllerLoad(forRowAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Para cada indexPath dado
        indexPaths.forEach { indexPath in
            // Invocamos el método `preload()` para activar una precarga de image
            cellController(forRowAt: indexPath).preload()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelCellControllerLoad)
    }
    
    private func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        // Obtenemos el model de la tabla para el índice dado
        return tableModel[indexPath.row]
    }
    
    private func cancelCellControllerLoad(forRowAt indexPath: IndexPath) {
        // Detenmos la tarea y libera memoria
        cellController(forRowAt: indexPath).cancelLoad()
    }
}
