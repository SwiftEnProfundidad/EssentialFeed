//
//  UIRefreshControl+Helpers.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 29/8/23.
//

import UIKit

extension UIRefreshControl {
    func update(isRefreshing: Bool) {
        isRefreshing ? beginRefreshing() : endRefreshing()
    }
}
