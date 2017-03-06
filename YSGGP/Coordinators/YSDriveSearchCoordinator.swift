//
//  YSDriveSearchCoordinator.swift
//  YSGGP
//
//  Created by Yurii Boiko on 2/17/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SwiftMessages

class YSDriveSearchCoordinator : YSCoordinatorProtocol
{
    fileprivate var searchNavigationController: UINavigationController?
    fileprivate var driveCoordinator : YSDriveTopCoordinator = YSDriveTopCoordinator()
    fileprivate var storyboard: UIStoryboard?
    fileprivate weak var searchViewModel: YSDriveSearchViewModel?
    
    func start() { }
    
    func start(navigationController: UINavigationController?, storyboard: UIStoryboard?)
    {
        self.storyboard = storyboard
        let searchControllerNavigation = storyboard?.instantiateViewController(withIdentifier: YSConstants.kDriveSearchNavigation) as! UINavigationController
        let searchController = searchControllerNavigation.viewControllers.first as! YSDriveSearchController
        
        let viewModel = YSDriveSearchViewModel()
        viewModel.model = YSDriveSearchModel()
        YSAppDelegate.appDelegate().fileDownloader?.downloadsDelegate = viewModel
        viewModel.coordinatorDelegate = self
        searchController.viewModel = viewModel
        searchViewModel = viewModel
        navigationController?.present(searchControllerNavigation, animated: true)
        searchNavigationController = searchControllerNavigation
    }
}

extension YSDriveSearchCoordinator : YSDriveSearchViewModelCoordinatorDelegate
{
    func searchViewModelDidSelectFile(_ viewModel: YSDriveSearchViewModelProtocol, file: YSDriveFileProtocol)
    {
        if file.isAudio
        {
            if let url = file.localFilePath(), file.localFileExists()
            {
                let player = AVPlayer(url: url as URL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                searchNavigationController?.present(playerViewController, animated: true)
                {
                    playerViewController.player!.play()
                }
            }
            else
            {
                let error = YSError(errorType: YSErrorType.couldNotDownloadFile, messageType: Theme.warning, title: "Could not play song", message: "No local copy", buttonTitle: "Download")
                viewModel.viewDelegate?.downloadErrorDidChange(viewModel: viewModel, error: error, file: file)
            }
        }
        else
        {
            let driveTopVC = storyboard?.instantiateViewController(withIdentifier: YSDriveTopViewController.nameOfClass) as! YSDriveTopViewController
            searchNavigationController?.pushViewController(driveTopVC, animated: true)
            let ysFolder = YSFolder()
            ysFolder.folderID = file.fileDriveIdentifier
            ysFolder.folderName = file.fileName
            driveCoordinator.folder = ysFolder
            driveCoordinator.start(driveTopVC: driveTopVC)
        }
    }
    
    func searchViewModelDidFinish()
    {
        YSAppDelegate.appDelegate().searchCoordinator = nil
    }
    
    func subscribeToDownloadingProgress()
    {
        YSAppDelegate.appDelegate().fileDownloader?.downloadsDelegate = searchViewModel
    }
}
