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

class YSDriveTopCoordinator: YSCoordinatorProtocol {
    var driveCoordinators = Set<YSDriveCoordinator>()
    fileprivate var navigationController: UINavigationController?
    var folders = [YSFolder.rootFolder()]
    fileprivate var storyboard: UIStoryboard?
    var shouldShowSearch = true

    func start(driveTopVC: YSDriveTopViewController, shouldShowSearch: Bool = true) {
        driveTopVC.driveVCReadyDelegate = self
        storyboard = driveTopVC.storyboard
        self.shouldShowSearch = shouldShowSearch
        driveTopVC.shouldShowSearch = shouldShowSearch
    }

    func driveCoordinatorDidRequestedLogin() {
        if let tababarController = YSAppDelegate.appDelegate().window!.rootViewController as? UITabBarController {
            tababarController.selectedIndex = 2 //settings tab
        }
    }

    func getFilesAfterSuccessLogin() {
        driveCoordinators.first?.start()
    }
}

extension YSDriveTopCoordinator: YSDriveViewControllerDidFinishedLoading {
    func driveViewControllerDidLoaded(driveVC: YSDriveViewController, navigationController: UINavigationController) {
        self.navigationController = navigationController
        let driveCoordinator = YSDriveCoordinator(driveViewController: driveVC, folder: folders.last!)
        driveCoordinator.start()
        driveCoordinator.delegate = self
        driveCoordinators.insert(driveCoordinator)
    }
}

extension YSDriveTopCoordinator: YSDriveCoordinatorDelegate {
    func driveCoordinatorDidFinish(driveCoordinator: YSDriveCoordinator, error: YSErrorProtocol?) {
        folders.remove(at: folders.count - 1)
        driveCoordinators.remove(driveCoordinator)
    }

    func driveCoordinatorDidSelectFile(_ viewModel: YSDriveViewModelProtocol, file: YSDriveFileProtocol) {
        if file.isAudio {
            if let url = file.localFilePath(), file.localFileExists() {
                let player = AVPlayer(url: url as URL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                YSAppDelegate.topViewController()?.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            } else {
                let error = YSError(errorType: YSErrorType.couldNotDownloadFile, messageType: Theme.warning, title: "Could not play song", message: "No local copy", buttonTitle: "Download")
                viewModel.viewDelegate?.downloadErrorDidChange(viewModel: viewModel, error: error, id: file.id)
            }
        } else {
            var ysfolder = YSFolder()
            ysfolder.folderID = file.id
            ysfolder.folderName = file.name
            folders.append(ysfolder)
            guard let driveTopVC = storyboard?.instantiateViewController(withIdentifier: YSDriveTopViewController.nameOfClass) as? YSDriveTopViewController else { return }
            driveTopVC.driveVCReadyDelegate = self
            driveTopVC.shouldShowSearch = shouldShowSearch
            driveTopVC.navigationTitleStr = file.name
            navigationController?.pushViewController(driveTopVC, animated: true)
        }
    }

    func driveViewControllerDidRequestedSearch() {
        let searchCoordinator = YSDriveSearchCoordinator()
        YSAppDelegate.appDelegate().searchCoordinator = searchCoordinator
        searchCoordinator.start(navigationController: navigationController, storyboard: storyboard)
    }
}
