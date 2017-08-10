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
import SwiftyBeaver
import UserNotifications
import SafariServices

protocol YSUpdatingDelegate: class
{
    func downloadDidChange(_ download : YSDownloadProtocol,_ error: YSErrorProtocol?)
    func filesDidChange()
}

//TODO: if we download file from search show it in playlist, when deleting downloads delete all from disk

@UIApplicationMain
class YSAppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    var driveTopCoordinator : YSDriveTopCoordinator?
    var backgroundSession : URLSession?
    var backgroundSessionCompletionHandler: (() -> Void)?
    var fileDownloader : YSDriveFileDownloader = YSDriveFileDownloader()
    var searchCoordinator : YSDriveSearchCoordinator?
    var playerCoordinator : YSPlayerCoordinator = YSPlayerCoordinator()
    var filesOnDisk : Set<String> = Set<String>()
    
    weak var downloadsDelegate: YSUpdatingDelegate?
    weak var playlistDelegate: YSUpdatingDelegate?
    weak var playerDelegate: YSUpdatingDelegate?
    weak var driveDelegate: YSUpdatingDelegate?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        //logs
        Reqres.register()
        let console = ConsoleDestination()  // log to Xcode Console
        let file = FileDestination()  // log to default swiftybeaver.log file
        let cloud = SBPlatformDestination(appID: "jxEkNM", appSecret: "32aci7cuhuqZ5fu7xgzorJHl0tc9wBsj", encryptionKey: "7rVx2pj3mLz1wnwlduyhphojdxnrrxil") // to cloud
        // add the destinations to SwiftyBeaver
        console.format = "$Dyyyy-MM-dd HH:mm:ss$d $T $N.$F:$l - $M"
        file.format = "$Dyyyy-MM-dd HH:mm:ss$d $T $N.$F:$l - $M"
        cloud.format = "$Dyyyy-MM-dd HH:mm:ss$d $T $N.$F:$l - $M"
        let log = SwiftyBeaver.self
        log.addDestination(console)
        log.addDestination(file)
        log.addDestination(cloud)
        
        log.info("Logs set up")
        
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: YSConstants.kDefaultBlueColor], for:.selected)
        UITabBar.appearance().tintColor = YSConstants.kDefaultBlueColor
        
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().signInSilently()
        
        log.info("FIRApp, GIDSignIn - configured")
        
        lookUpAllFilesOnDisk()
        
        log.info("looked Up All Files On Disk")
        
//        YSDatabaseManager.deleteDatabase { (error) in
//            //TODO: remove this
//            log.error("DATABASE DELETED")
//            let when = DispatchTime.now() + 3
//            DispatchQueue.main.asyncAfter(deadline: when)
//            {
//                self.driveDelegate?.filesDidChange()
//            }
//        }
        
        log.info("Register for notifications")
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization( options: authOptions, completionHandler: { (granted, error) in
            guard granted else { return }
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                guard settings.authorizationStatus == .authorized else { return }
                application.registerForRemoteNotifications()
            }
        })
        log.info("Finished registering for notifications")
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
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        let log = SwiftyBeaver.self
        log.info("")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        let log = SwiftyBeaver.self
        log.info("")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        let log = SwiftyBeaver.self
        log.info("")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let log = SwiftyBeaver.self
        log.info("")
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
            filesOnDisk = Set<String>().union(mp3FileNames)
        }
        catch let error as NSError
        {
            let log = SwiftyBeaver.self
            log.error("lookUpAllFilesOnDisk - \(error.localizedDescription)")
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        let log = SwiftyBeaver.self
        log.info("Successfully registered for notifications. Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        let log = SwiftyBeaver.self
        log.info("Failed to register: \(error)")
    }
    
//    {
//    "aps": {
//    "content-available": 0
//    }
//    }
    //recieves remote silent notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let aps = userInfo["aps"] as! [String: AnyObject]
        
        let log = SwiftyBeaver.self
        log.info("Recieved remote silent notification: \(aps)")
        if aps["content-available"] as? Int == 1 {
            completionHandler(.newData)
        } else {
            completionHandler(.newData)
        }
    }
}

extension YSAppDelegate : UNUserNotificationCenterDelegate
{
//    {
//    "aps": {
//    "alert": "New version!",
//    "sound": "default",
//    "link_url": "https://github.com/Yurssoft/QuickFile"
//    }
//    }
    //recieves push notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        let log = SwiftyBeaver.self
        log.info("Recieved push notification: \(response.notification.request.content.userInfo)")
        let userInfo = response.notification.request.content.userInfo
        let aps = userInfo["aps"] as! [String: AnyObject]
        
        if let urlString = aps["link_url"], let url = URL(string: urlString as! String)
        {
            let safari = SFSafariViewController(url: url)
            window?.rootViewController?.present(safari, animated: true, completion: nil)
        }
        
        completionHandler()
    }
}
