//
//  UITableView + Dequeueing.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 26/8/23.
//

import UIKit

extension UITableView {
    // Devuleve una `Cell` no opcional escrita
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let identifier = String(describing: T.self)
        // Devuelve una `Cell` reutilizable con el identificador y lo convertimos al tipo deseado
        return dequeueReusableCell(withIdentifier: identifier) as! T
    }
}

