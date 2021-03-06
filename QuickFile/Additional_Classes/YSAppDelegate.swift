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
import NSLogger
import UserNotifications
import SafariServices
import Reqres
import AVFoundation

protocol YSUpdatingDelegate: class {
    func downloadDidChange(_ download: YSDownloadProtocol, _ error: YSErrorProtocol?)
    func filesDidChange()
}

/* TODO:
 - search add loading indicator
 - show all downloads in playlist
 - logged as
 - firebase functions?
 - add spotlight search
 - add search in playlist
 - delete played files after 24 hours
 - display all files in drive and use document previewer for all files
 - make downloads in order
 - add tutorial screen
 - battery life
 - send logs
 - share extension
 - google analytics
 - playlist delete downloads
 - reverse sorting of files
 - rethink relogin, what to do with current data and downloads and current downloads
 - update to crashlitycs
 - fix wrong player reload after download
 - understand that uitabbarcontroller is already acting as coordinator, remove segways and as first step start viewmodel loading only after view did loaded
 - display current playing in drive VC
 - what happens to logs on no storage?
 - stop player when playing locally from cell
 - in search go to some foler - update downloads in this folder - go back to search - download changes are not reflected in search
 - why sometimes size of mp3 is not displayed?
 - do not save file to disk in main thread
 - possibility to play files from local storage with folder "local"
 - crash on typing ukrainian characters in search
 - show played sign in drive files to make a shortcut when you need to download file to see if it is played
 - show playlist as tree and open/close it
 - scroll playlist to currently playing song
 */

@UIApplicationMain
class YSAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var driveTopCoordinator: YSDriveTopCoordinator?
    var searchCoordinator: YSDriveSearchCoordinator?
    var playerCoordinator = YSPlayerCoordinator()
    var settingsCoordinator = YSSettingsCoordinator()
    var playlistCoordinator = YSPlaylistCoordinator()
    var backgroundSession: URLSession?
    var backgroundSessionCompletionHandler: (() -> Void)?
    var fileDownloader: YSDriveFileDownloader = YSDriveFileDownloader()
    var filesOnDisk = Set<String>()

    weak var downloadsDelegate: YSUpdatingDelegate?
    weak var playlistDelegate: YSUpdatingDelegate?
    weak var playerDelegate: YSUpdatingDelegate?
    weak var driveDelegate: YSUpdatingDelegate?

    override init() {
        super.init()
        UIViewController.classInit
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        startNSLogger()
        Reqres.logger = ReqresDefaultLogger()
        Reqres.register()
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: YSConstants.kDefaultBlueColor], for: .selected)
        UITabBar.appearance().tintColor = YSConstants.kDefaultBlueColor

        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().signInSilently()

        logDefault(.App, .Info, "FIRApp, GIDSignIn - configured")

        lookUpAllFilesOnDisk()

        logDefault(.App, .Info, "looked Up All Files On Disk")

//        YSDatabaseManager.deleteDatabase { (error) in
//            //TODO: REMOVES DATABASE
//            logDefault(.App, .Error, "DATABASE DELETED")
//            logDefault(.App, .Error, "DATABASE DELETED")
//            logDefault(.App, .Error, "DATABASE DELETED")
//            let when = DispatchTime.now() + 3
//            DispatchQueue.main.asyncAfter(deadline: when) {
//                self.driveDelegate?.filesDidChange()
//            }
//        }

        logDefault(.App, .Info, "Register for notifications")
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization( options: authOptions, completionHandler: { (granted, _) in
            guard granted else { return }
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                guard settings.authorizationStatus == .authorized else { return }
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        })
        logDefault(.App, .Info, "Finished registering for notifications")
        configureAudioSession()
        return true
    }

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if #available(iOS 11.0, *) {
                try audioSession.setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeSpokenAudio, routeSharingPolicy: .longForm)
            } else {
                try audioSession.setCategory(AVAudioSessionCategoryPlayback)
                try audioSession.setMode(AVAudioSessionModeSpokenAudio)
            }
        } catch let error as NSError {
            logDefault(.App, .Error, "Error configuring audio session: " + error.localizedDescriptionAndUnderlyingKey)
        }
    }
    
    private func startNSLogger() {
        let logsDirectory = YSConstants.logsFolder
        do {
            try FileManager.default.createDirectory(atPath: logsDirectory.relativePath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            logDefault(.App, .Error, "Error creating directory: \(error.localizedDescription)")
        }
        removeOldestLogIfNeeded()

        let file = "\(logsDirectory.relativePath)/NSLoggerData-" + UUID().uuidString + ".rawnsloggerdata"
        LoggerSetBufferFile(nil, file as CFString)

        LoggerSetOptions(nil, UInt32(kLoggerOption_BufferLogsUntilConnection | kLoggerOption_BrowseBonjour | kLoggerOption_BrowseOnlyLocalDomain | kLoggerOption_LogToConsole))

        if let bundleName = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String {
            LoggerSetupBonjour(nil, nil, bundleName as CFString)
        }
        LoggerStart(nil)
    }

    private func removeOldestLogIfNeeded() {
        DispatchQueue.global(qos: .utility).async {
            logDefault(.App, .Info, "removeOldestLogIfNeeded")
            do {
                let urlArray = try FileManager.default.contentsOfDirectory(at: YSConstants.logsFolder, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
                if urlArray.count > YSConstants.kNumberOfLogsStored {
                    let fileUrlsSortedByDate = urlArray.map { url in
                        (url, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
                        }
                        .sorted(by: { $0.1 > $1.1 }) // sort descending modification dates
                        .map { $0.0 } // extract file urls
                    if let oldestLogFileUrl = fileUrlsSortedByDate.last {
                        try FileManager.default.removeItem(at: oldestLogFileUrl) // we delete the oldest log
                        logDefault(.App, .Info, "Removed oldest log: " + oldestLogFileUrl.relativePath)
                    }
                }
            } catch let error as NSError {
                logDefault(.App, .Error, "Error while working with logs folder contents \(error.localizedDescription)")
            }
        }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url as URL!, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundSessionCompletionHandler = completionHandler
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        logDefault(.App, .Info, "")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        logDefault(.App, .Info, "")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        logDefault(.App, .Info, "")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        logDefault(.App, .Info, "")
    }

    class func appDelegate() -> YSAppDelegate {
        guard let delegate = UIApplication.shared.delegate as? YSAppDelegate else {
            return YSAppDelegate()
        }
        return delegate
    }
    
    class func topViewController() -> UIViewController? {
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }

    private func lookUpAllFilesOnDisk() {
        filesOnDisk = YSDatabaseManager.getAllnamesOnDisk()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        logDefault(.App, .Info, "Successfully registered for notifications. Device Token: \(token)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logDefault(.App, .Info, "Failed to register: \(error)")
    }

//    {
//    "aps": {
//    "content-available": 0
//    }
//    }
    //recieves remote silent notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let aps = userInfo[forKey: "aps", ""]
        logDefault(.App, .Info, "Recieved remote silent notification: \(aps)")
        if aps.count > 0 {
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
}

extension YSAppDelegate: UNUserNotificationCenterDelegate {
//    {
//    "aps": {
//    "alert": "New version!",
//    "sound": "default",
//    "link_url": "https://github.com/Yurssoft/QuickFile"
//    }
//    }
    //recieves push notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        logDefault(.App, .Info, "Recieved push notification: \(response.notification.request.content.userInfo)")
        let userInfo = response.notification.request.content.userInfo
        let aps = userInfo[forKey: "aps", [String: Any]()]
        let urlString = aps[forKey: "link_url", ""]
        if urlString.count > 0, let url = URL(string: urlString) {
            let safari = SFSafariViewController(url: url)
            window?.rootViewController?.present(safari, animated: true, completion: nil)
        }

        completionHandler()
    }
}
