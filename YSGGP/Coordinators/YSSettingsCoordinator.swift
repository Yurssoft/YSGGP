//
//  YSSettingsCoordinator.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/17/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit

class YSSettingsCoordinator: YSCoordinatorProtocol
{
    fileprivate var settingsViewController: YSSettingsTableViewController?
    
    init(settingsViewController: YSSettingsTableViewController, navigationController: UINavigationController)
    {
        self.settingsViewController = settingsViewController
    }
    
    func start()
    {
        let viewModel = YSSettingsViewModel()
        settingsViewController?.viewModel = viewModel
        viewModel.model = YSSettingsModel()
    }
}
