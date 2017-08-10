//
//  YSSettingsViewModelProtocol.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/17/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation

protocol YSSettingsViewModelViewDelegate: class
{
    func errorDidChange(viewModel: YSSettingsViewModel, error: YSErrorProtocol)
}

protocol YSSettingsCoordinatorDelegate: class
{
    func viewModelSuccessfullyLoggedIn(viewModel: YSSettingsViewModel)
    func viewModelDidDeleteAllLocalFiles(viewModel: YSSettingsViewModel)
}

protocol YSSettingsViewModelProtocol
{
    var isLoggedIn : Bool { get }
    var loggedString : String { get }
    weak var coordinatorDelegate: YSSettingsCoordinatorDelegate? { get set }
    func logOut()
    func deleteAllFiles()
    func deletePlayedFiles()
    func successfullyLoggedIn()
}
