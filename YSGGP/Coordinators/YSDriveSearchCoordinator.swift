//
//  YSDriveSearchCoordinator.swift
//  YSGGP
//
//  Created by Yurii Boiko on 2/17/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import UIKit

class YSDriveSearchCoordinator : YSCoordinatorProtocol
{
    fileprivate var navigationController: UINavigationController?
    
    func start() { }
    
    func start(navigationController: UINavigationController?, storyboard: UIStoryboard?)
    {
        self.navigationController = navigationController
        let searchControllerNavigation = storyboard?.instantiateViewController(withIdentifier: YSConstants.kDriveSearchNavigation) as! UINavigationController
        let searchController = searchControllerNavigation.viewControllers.first as! YSDriveSearchController
        
        searchController.viewModel = YSDriveSearchViewModel()
        searchController.viewModel?.model = YSDriveSearchModel()
//        searchController.viewModel?a.coordinatorDelegate = self
        
        navigationController?.present(searchControllerNavigation, animated: true)
    }
}

//extension YSDriveSearchCoordinator : 
