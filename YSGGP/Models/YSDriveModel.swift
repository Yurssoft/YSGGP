//
//  YSDriveModel.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/23/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import GoogleAPIClient
import GTMOAuth2
import SwiftMessages

class YSDriveModel: NSObject, YSDriveModelProtocol
{
    var isLoggedIn : Bool
    {
        return YSDriveManager.sharedInstance.isLoggedIn
    }
    
    func items(_ completionHandler: (([YSDriveItem], YSError?) -> Swift.Void)? = nil)
    {
        if completionHandler == nil
        {
            return
        }
        YSDriveManager.sharedInstance.login()
        if isLoggedIn
        {
            let query = GTLQueryDrive.queryForFilesList()
            query?.pageSize = 10
            query?.fields = "nextPageToken, files(id, name, size)"
            let parentID = "root"
            query?.q = NSString(format: "%@ in parents", parentID) as String!
            
            var items : [YSDriveItem]
            items = []
            YSDriveManager.sharedInstance.service.executeQuery(query!, completionHandler: { (ticket, response1, error) in
                let response = response1 as? GTLDriveFileList
                if let files = response?.files , !files.isEmpty
                {
                    for file in files as! [GTLDriveFile]
                    {
                        let item = YSDriveItem(fileName: file.name, fileInfo: file.identifier, fileURL: file.size.stringValue, isAudio: false)
                        items.append(item)
                    }
                    if error != nil
                    {
                        let error = YSError(errorType: YSErrorType.couldNotGetFileList, messageType: Theme.error, title: "Error", message: "Couldn't get data from Drive", buttonTitle: "Try again")
                        completionHandler!(items, error)
                        return
                    }
                    completionHandler!(items, YSError())
                }
            })
        }
        else
        {
            var items : [YSDriveItem]
            items = []
            for i in (0..<200)
            {
                let item = YSDriveItem(fileName: "\(i)", fileInfo: "\(i)", fileURL:"\(i)", isAudio: false)
                items.append(item)
            }
            let error = YSError(errorType: YSErrorType.notLoggedInToDrive, messageType: Theme.info, title: "Not logged in", message: "You are not logged in to drive", buttonTitle: "Login")
            completionHandler!(items, error)
        }
    }
}