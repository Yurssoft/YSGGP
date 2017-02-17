//
//  YSAppCoordinator.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/28/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit

protocol YSDriveCoordinatorDelegate: class
{
    func driveCoordinatorDidFinish(driveVC: YSDriveCoordinator, error: YSErrorProtocol?)
    func driveCoordinatorDidSelectFile(_ viewModel: YSDriveViewModelProtocol, file: YSDriveFileProtocol)
    func driveCoordinatorDidRequestedLogin()
    func driveViewControllerDidRequestedSearch()
}

class YSDriveCoordinator: NSObject, YSCoordinatorProtocol
{
    fileprivate let driveViewController: YSDriveViewController
    weak var delegate : YSDriveCoordinatorDelegate?
    var folder : YSFolder = YSFolder()
    
    init(driveViewController: YSDriveViewController, folder: YSFolder)
    {
        self.driveViewController = driveViewController
        self.folder = folder
    }
    
    func start()
    {
        let viewModel = YSDriveViewModel()
        YSAppDelegate.appDelegate().fileDownloader?.downloadsDelegate = viewModel
        viewModel.model = YSDriveModel(folder: folder)
        viewModel.coordinatorDelegate = self
        driveViewController.viewModel = viewModel
    }
    
    func updateDownloadDelegate()
    {
        YSAppDelegate.appDelegate().fileDownloader?.downloadsDelegate = driveViewController.viewModel as? YSDriveFileDownloaderDelegate
    }
    
    fileprivate func start(folderID: String,error: YSError?)
    {
        let viewModel =  YSDriveViewModel()
        driveViewController.viewModel = viewModel
        viewModel.model = YSDriveModel(folder: folder)
        viewModel.coordinatorDelegate = self
        if error == nil
        {
            return
        }
        viewModel.viewDelegate?.errorDidChange(viewModel: viewModel, error: error!)
    }
}

extension YSDriveCoordinator: YSDriveViewModelCoordinatorDelegate
{
    func driveViewModelDidSelectFile(_ viewModel: YSDriveViewModelProtocol, file: YSDriveFileProtocol)
    {
        delegate?.driveCoordinatorDidSelectFile(viewModel, file: file)
    }

    func driveViewModelDidRequestedLogin()
    {
        delegate?.driveCoordinatorDidRequestedLogin()
    }
    
    func driveViewModelDidFinish()
    {
        delegate?.driveCoordinatorDidFinish(driveVC: self, error: nil)
    }
    
    func driveViewControllerDidRequestedSearch()
    {
        delegate?.driveViewControllerDidRequestedSearch()
    }
}
