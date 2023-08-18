//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 18/8/23.
//

import UIKit
import EssentialFeed

final public class FeedViewController: UITableViewController {
    private var loader: FeedLoader?
    // Hacemos que nuestro init sea de conveniencia, dado que no
    // necesitamos un inicializador personalizado, por lo que no
    // necesitamos implementar el inicializado requerido de UIViewController
    public convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }
    
    @objc private func load() {
        refreshControl?.beginRefreshing()
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}
