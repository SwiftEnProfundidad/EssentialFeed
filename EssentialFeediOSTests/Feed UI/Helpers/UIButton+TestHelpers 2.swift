//
//  UIButton+TestHelpers.swift
//  EssentialFeediOSTests
//
//  Created by Juan Carlos Merlos Albarracin on 28/8/23.
//

import UIKit

extension UIButton {
    func simulateTap() {
        simulate(event: .touchUpInside)
    }
}
