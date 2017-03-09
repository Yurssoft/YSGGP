//
//  YSPlayerCoordinator.swift
//  YSGGP
//
//  Created by Yurii Boiko on 12/28/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SwiftMessages
import MediaPlayer

class YSPlayerCoordinator: YSCoordinatorProtocol
{
    func start() { }
    
    var viewModel = YSPlayerViewModel.init()
    fileprivate var tabBarController: UITabBarController?
    fileprivate var popupContentController: YSPlayerController?
    
    func start(tabBarController: UITabBarController)
    {
        self.tabBarController = tabBarController
        let model = YSPlaylistAndPlayerModel()
        viewModel.coordinatorDelegate = self
        viewModel.model = model
        YSAppDelegate.appDelegate().playerDelegate = viewModel
    }
    
    func play(file: YSDriveFileProtocol)
    {
        viewModel.play(file: file)
    }
}

extension YSPlayerCoordinator : YSPlayerViewModelCoordinatorDelegate
{
    func showPlayer()
    {
        DispatchQueue.main.async
        {
            if self.tabBarController?.popupPresentationState != .hidden
            {
                return
            }
            let audioSession = AVAudioSession.sharedInstance()
            try! audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try! audioSession.setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            self.popupContentController = self.tabBarController?.storyboard?.instantiateViewController(withIdentifier: YSPlayerController.nameOfClass) as? YSPlayerController
            self.popupContentController?.viewModel = self.viewModel
            self.tabBarController?.presentPopupBar(withContentViewController: self.popupContentController!, animated: true, completion: nil)
            self.tabBarController?.popupBar.tintColor = YSConstants.kDefaultBlueColor
            self.tabBarController?.popupBar.subtitleTextAttributes = [NSForegroundColorAttributeName: UIColor.lightGray]
        }
    }
}
