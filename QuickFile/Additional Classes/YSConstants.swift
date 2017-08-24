//
//  YSConstants.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/28/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import UIKit
import SwiftMessages

typealias FilesCompletionHandler = (_ files:[YSDriveFileProtocol]) -> Swift.Void
typealias ErrorCompletionHandler = (_ error:YSErrorProtocol?) -> Swift.Void

struct YSConstants
{
    static let kDriveClientID = "416980241627-jl0l2kt36fd7soan5k8hlhtsgfkoblns.apps.googleusercontent.com" 
    static let kStoryboardName = "Main"
    static let kDriveEmbededSegue = "YSDriveViewControllerSegue"
    static let kSettingsEmbededSegue = "YSSettingsViewControllerSegue"
    static let kDriveAPIKey = "AIzaSyCMsksSn6-1FzYhN49uDAzN83HGvFVXqaU"
    static let kDriveAPIEndpoint = "https://www.googleapis.com/drive/v3/"
    static let kAccessTokenAPIEndpoint = "https://www.googleapis.com/oauth2/v4/token"
    static let kObtainUserAuthorizationAPIEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    static let kTokenKeychainKey = "kTokenKeychainKey"
    static let kTokenKeychainItemKey = "kTokenKeychainItemKey"
    static let kDriveScopes = ["https://www.googleapis.com/auth/drive.readonly"]
    static let kFirstPageToken = "kFirstPageToken"
    static let kDriveSearchNavigation = "YSDriveSearchControllerNavigation"
    static let kOffineStatusBarMessageID = "kOffineStatusBarMessageID"
    static let kCellHeight = CGFloat(50.0)
    static let kHeaderHeight = CGFloat(28.0)
    static let kPageSize = 100
    static let kDefaultBlueColor = UIColor(red:23/255.0, green:156/255.0, blue:209/255.0, alpha:1.0)
    static let kDefaultBarColor = UIColor(red:254/255.0, green:213/255.0, blue:165/255.0, alpha:1.0)
    static let kMessageDuration = SwiftMessages.Duration.automatic
}

enum YSErrorType
{
    case none
    case couldNotGetFileList
    case cancelledLoginToDrive
    case couldNotLoginToDrive
    case loggedInToToDrive
    case notLoggedInToDrive
    case couldNotLogOutFromDrive
    case couldNotDownloadFile
}
