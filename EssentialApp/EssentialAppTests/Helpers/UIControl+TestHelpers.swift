//
//  UIControl+TestHelpers.swift
//  EssentialFeediOSTests
//
//  Created by Juan Carlos Merlos Albarracin on 28/8/23.
//

import UIKit

extension UIControl {
    func simulate(event: UIControl.Event) {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: event)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
