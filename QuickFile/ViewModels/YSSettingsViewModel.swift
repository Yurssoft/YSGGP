//
//  YSSettingsViewModel.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/17/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import SwiftMessages
import GoogleSignIn

class YSSettingsViewModel : YSSettingsViewModelProtocol
{
    var isLoggedIn : Bool
    {
        return model!.isLoggedIn
    }

    var loggedString : String
    {
        if isLoggedIn
        {
            let loggedInMessage = "Logged in to Drive"
            return loggedInMessage
        }
        return "Not logged in"
    }
    
    fileprivate var error : YSErrorProtocol = YSError()
    {
        didSet
        {
            if !error.isEmpty()
            {
                viewDelegate?.errorDidChange(viewModel: self, error: error)
            }
        }
    }
    
    weak var viewDelegate: YSSettingsViewModelViewDelegate?
    var model : YSSettingsModel?
    weak var coordinatorDelegate: YSSettingsCoordinatorDelegate?
    
    func logOut()
    {
        do
        {
            try model?.logOut()
        }
        catch
        {
            viewDelegate?.errorDidChange(viewModel: self, error: error as! YSErrorProtocol)
        }
    }
    
    //TODO: player delete current playing
    func deleteAllFiles()
    {
        YSDatabaseManager.deleteAllDownloads { (error) in
            DispatchQueue.main.async
            {
                guard let error = error else { return }
                if error.messageType == Theme.success || error.title.contains("Deleted")
                {
                    self.coordinatorDelegate?.viewModelDidDeleteAllLocalFiles(viewModel: self)
                }
                self.viewDelegate?.errorDidChange(viewModel: self, error: error)
            }
        }
    }
    
    func deletePlayedFiles()
    {
        YSDatabaseManager.deletePlayedDownloads { (error) in
            DispatchQueue.main.async
                {
                    guard let error = error else { return }
                    if error.messageType == Theme.success || error.title.contains("Deleted")
                    {
                        self.coordinatorDelegate?.viewModelDidDeleteAllLocalFiles(viewModel: self)
                    }
                    self.viewDelegate?.errorDidChange(viewModel: self, error: error)
            }
        }
    }
    
    func successfullyLoggedIn()
    {
        coordinatorDelegate?.viewModelSuccessfullyLoggedIn(viewModel: self)
    }
}
