//
//  UIView+TestHelpers.swift
//  EssentialAppTests
//
//  Created by Juan Carlos Merlos Albarracin on 7/9/23.
//

import UIKit

extension UIView {
    func enforceLayoutCycle() {
        layoutIfNeeded()
        RunLoop.current.run(until: Date())
    }
}
