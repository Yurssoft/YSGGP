//
//  ViewControllerLoggingExtension.swift
//  QuickFile
//
//  Created by Yurii Boiko on 9/24/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import UIKit

private let swizzling: (AnyClass, Selector, Selector) -> Void = { forClass, originalSelector, swizzledSelector in
    let originalMethod = class_getInstanceMethod(forClass, originalSelector)
    let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector)
    method_exchangeImplementations(originalMethod!, swizzledMethod!)
}

extension UIViewController {

    static let classInit: Void = {
        var originalSelector = #selector(viewDidLoad)
        var swizzledSelector = #selector(swizzled_viewDidLoad)
        swizzling(UIViewController.self, originalSelector, swizzledSelector)

        originalSelector = #selector(viewDidAppear)
        swizzledSelector = #selector(swizzled_viewDidLoad)
        swizzling(UIViewController.self, originalSelector, swizzledSelector)

        originalSelector = #selector(viewDidDisappear)
        swizzledSelector = #selector(swizzled_viewDidLoad)
        swizzling(UIViewController.self, originalSelector, swizzledSelector)
    }()

    @objc func swizzled_viewDidLoad() {
        swizzled_viewDidLoad()
        logDefault(.Controller, .Info, self.nameOfClass + ": viewDidLoad()")
    }

    func swizzled_viewDidAppear() {
        swizzled_viewDidAppear()
        logDefault(.Controller, .Info, self.nameOfClass + ": viewDidAppear()")
    }

    func swizzled_viewDidDisappear() {
        swizzled_viewDidDisappear()
        logDefault(.Controller, .Info, self.nameOfClass + ": viewDidDisappear()")
    }
}
