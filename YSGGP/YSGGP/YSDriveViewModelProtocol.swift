//
//  YSDriveViewModelViewDelegate.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/22/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation

protocol YSDriveViewModelViewDelegate: class
{
    func itemsDidChange(viewModel: YSDriveViewModel)
}

protocol YSDriveViewModelCoordinatorDelegate: class
{
    func driveViewModelDidSelectData(_ viewModel: YSDriveViewModel, data: YSDriveItem)
    func driveViewModelDidRequestedLogin()
}

protocol YSDriveViewModelProtocol
{
    var model: YSDriveModel? { get set }
    var viewDelegate: YSDriveViewModelViewDelegate? { get set }
    var coordinatorDelegate: YSDriveViewModelCoordinatorDelegate? { get set}
    var numberOfItems: Int { get }
    
    func itemAtIndex(_ index: Int) -> YSDriveItem?
    func useItemAtIndex(_ index: Int)
    func loginToDrive()
}
