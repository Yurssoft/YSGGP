//
//  YSDriveTopCoordinator.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/25/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SwiftMessages

class YSDriveTopCoordinator: YSCoordinatorProtocol
{
    fileprivate var driveCoordinators : [YSDriveCoordinator] = []
    fileprivate var navigationController: UINavigationController?
    fileprivate var folder : YSFolder = YSFolder.rootFolder()
    fileprivate var storyboard: UIStoryboard?
    
    func start() { }
    
    func start(driveTopVC: YSDriveTopViewController)
    {
        driveTopVC.driveVCReadyDelegate = self
        storyboard = driveTopVC.storyboard
    }
    
    func driveCoordinatorDidRequestedLogin()
    {
        if let tababarController = YSAppDelegate.appDelegate().window!.rootViewController as? UITabBarController
        {
            tababarController.selectedIndex = 2 //settings tab
        }
    }
}

extension YSDriveTopCoordinator : YSDriveViewControllerDidFinishedLoading
{
    func driveViewControllerDidLoaded(driveVC: YSDriveViewController, navigationController: UINavigationController)
    {
        self.navigationController = navigationController
        let driveCoordinator = YSDriveCoordinator(driveViewController: driveVC, folder: folder)
        driveCoordinator.start()
        driveCoordinator.delegate = self
        driveCoordinators.append(driveCoordinator)
    }
}

extension YSDriveTopCoordinator : YSDriveCoordinatorDelegate
{
    func driveCoordinatorDidFinish(driveVC: YSDriveCoordinator, error: YSErrorProtocol?)
    {
        if let index = driveCoordinators.index(of: driveVC)
        {
            driveCoordinators.remove(at: index)
            var viewControllers : [UIViewController] = []
            for i in 0...(navigationController?.childViewControllers.count)! - 1
            {
                viewControllers.append((navigationController?.childViewControllers[i])!)
            }
            navigationController?.setViewControllers(viewControllers, animated: false)
            if let lastCoordinator = driveCoordinators.last
            {
                folder = lastCoordinator.folder
            }
            else
            {
                folder = YSFolder.rootFolder()
            }
        }
    }
    
    func driveCoordinatorDidSelectFile(_ viewModel: YSDriveViewModelProtocol, file: YSDriveFileProtocol)
    {
        if file.isAudio
        {
            if let url = file.localFilePath(), file.isFileOnDisk
            {
                let player = AVPlayer(url: url as URL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                navigationController?.present(playerViewController, animated: true)
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
            let ysfolder = YSFolder()
            ysfolder.folderID = file.fileDriveIdentifier
            ysfolder.folderName = file.fileName
            folder = ysfolder
            let driveTopVC = storyboard?.instantiateViewController(withIdentifier: YSDriveTopViewController.nameOfClass) as! YSDriveTopViewController
            driveTopVC.driveVCReadyDelegate = self
            navigationController?.pushViewController(driveTopVC, animated: true)
        }
    }
}
