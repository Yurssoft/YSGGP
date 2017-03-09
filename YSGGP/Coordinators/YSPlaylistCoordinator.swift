//
//  YSPlaylistCoordinator.swift
//  YSGGP
//
//  Created by Yurii Boiko on 12/7/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import SwiftMessages

protocol YSPlaylistCoordinatorDelegate: class
{
    func playlistCoordinatorDidRequestToPlayFile(driveVC: YSDriveCoordinator, file: YSDriveFileProtocol)
}

class YSPlaylistCoordinator: YSCoordinatorProtocol
{
    fileprivate var playlistViewController: YSPlaylistViewController
    weak var delegate : YSPlaylistCoordinatorDelegate?
    let navigationController: UINavigationController
    var playerCoordinator : YSPlayerCoordinator?
    
    init(playlistViewController: YSPlaylistViewController, navigationController: UINavigationController)
    {
        self.playlistViewController = playlistViewController
        self.navigationController = navigationController
    }
    
    func start()
    {
        let viewModel =  YSPlaylistViewModel()
        playlistViewController.viewModel = viewModel
        YSAppDelegate.appDelegate().playerCoordinator.viewModel.playerDelegate = playlistViewController
        YSAppDelegate.appDelegate().playlistDelegate = viewModel
        viewModel.model = YSPlaylistAndPlayerModel()
        viewModel.coordinatorDelegate = self
    }
}

extension YSPlaylistCoordinator : YSPlaylistViewModelCoordinatorDelegate
{
    func playlistViewModelDidSelectFile(_ viewModel: YSPlaylistViewModelProtocol, file: YSDriveFileProtocol)
    {
        YSAppDelegate.appDelegate().playerCoordinator.play(file: file)
    }
}
