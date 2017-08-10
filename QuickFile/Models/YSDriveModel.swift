//
//  YSDriveModel.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/23/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import SwiftMessages
import SwiftyBeaver

class YSDriveModel: YSDriveModelProtocol
{
    var isLoggedIn : Bool
    {
        return YSCredentialManager.isLoggedIn
    }
    
    fileprivate weak var currentFolder : YSFolder?
    
    init(folder: YSFolder?)
    {
        currentFolder = folder
    }
    
    func getFiles(pageToken: String, nextPageToken: String?,_ completionHandler: @escaping AllFilesCompletionHandler)
    {
        var url = "\(YSConstants.kDriveAPIEndpoint)files?"
        //TODO: remove duplicated and deprecated code
        if let nextPageToken = nextPageToken
        {
            let encodedNextPageToken = CFURLCreateStringByAddingPercentEscapes(
                nil,
                nextPageToken as CFString!,
                nil,
                "!'();:@&=+$,/?%#[]" as CFString!,
                CFStringBuiltInEncodings.ASCII.rawValue
                ) as String
            url.append("pageToken=\(encodedNextPageToken)&")
        }
        guard let folder = currentFolder else
        {
            let log = SwiftyBeaver.self
            log.error("No folder")
            return
        }
        url.append("corpus=user&orderBy=folder%2Cname&pageSize=\(YSConstants.kPageSize)&q='\(folder.folderID)'+in+parents+and+(mimeType+contains+'folder'+or+mimeType+contains+'audio')+and+trashed%3Dfalse&spaces=drive&fields=nextPageToken%2C+files(id%2C+name%2C+size%2C+mimeType)&key=\(YSConstants.kDriveAPIKey)")
        YSFilesMetadataDownloader.downloadFilesList(for: url)
        { filesDictionary, error in
            if let err = error
            {
                let yserror = err as! YSError
                YSDatabaseManager.offlineFiles(folder: folder, yserror, completionHandler)
                return
            }
            YSDatabaseManager.save(pageToken: pageToken, remoteFilesDict: filesDictionary!, folder, completionHandler)
        }
    }
    
    func download(for file: YSDriveFileProtocol) -> YSDownloadProtocol?
    {
        return YSAppDelegate.appDelegate().fileDownloader.download(for: file)
    }
    
    func download(_ file : YSDriveFileProtocol)
    {
        YSAppDelegate.appDelegate().fileDownloader.download(file: file)
    }
    
    func stopDownload(_ file : YSDriveFileProtocol)
    {
        YSAppDelegate.appDelegate().fileDownloader.cancelDownloading(file: file)
    }
}
