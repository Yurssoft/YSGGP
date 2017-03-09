//
//  AppDelegate.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/19/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit
import GTMOAuth2
import Firebase
import GoogleSignIn

protocol YSUpdatingDelegate: class
{
    func downloadDidChange(_ download : YSDownloadProtocol,_ error: YSErrorProtocol?)
    func filesDidChange()
}

@UIApplicationMain
class YSAppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    var driveTopCoordinator : YSDriveTopCoordinator?
    var backgroundSession : URLSession?
    var backgroundSessionCompletionHandler: (() -> Void)?
    var fileDownloader : YSDriveFileDownloader?
    var searchCoordinator : YSDriveSearchCoordinator?
    var playerCoordinator : YSPlayerCoordinator = YSPlayerCoordinator()
    var filesOnDisk : [String] = []
    
    weak var downloadsDelegate: YSUpdatingDelegate?
    weak var playlistDelegate: YSUpdatingDelegate?
    weak var playerDelegate: YSUpdatingDelegate?
    weak var driveDelegate: YSUpdatingDelegate?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: YSConstants.kDefaultBlueColor], for:.selected)
        UITabBar.appearance().tintColor = YSConstants.kDefaultBlueColor
        //UITabBar.appearance().barTintColor = YSConstants.kDefaultBarColor
        
        //UINavigationBar.appearance().barTintColor = YSConstants.kDefaultBarColor
        //UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: YSConstants.kDefaultBlueColor]
        
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().signInSilently()
        fileDownloader = YSDriveFileDownloader()
        lookUpAllFilesOnDisk()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
    {
        return GIDSignIn.sharedInstance().handle(url as URL!, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
    {
        backgroundSessionCompletionHandler = completionHandler
    }
    
    class func appDelegate() -> YSAppDelegate
    {
        return UIApplication.shared.delegate as! YSAppDelegate
    }
    
    private func lookUpAllFilesOnDisk()
    {
        do
        {
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            let mp3Files = directoryContents.filter{ $0.pathExtension == "mp3" }
            let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
            filesOnDisk = mp3FileNames
        }
        catch let error as NSError
        {
            print(error.localizedDescription)
        }
    }
}

