//
//  YSDriveSearchModel.swift
//  YSGGP
//
//  Created by Yurii Boiko on 2/17/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import Foundation

class YSDriveSearchModel : YSDriveSearchModelProtocol
{
    func getFiles(for searchTerm: String, _ completionHandler: @escaping DriveSearchCompletionHandler)
    {
        let url = "\(YSConstants.kDriveAPIEndpoint)files?corpus=user&orderBy=folder,name&pageSize=100&q=name+contains+'\(searchTerm)'+and+(mimeType+contains+'folder'+or+mimeType+contains+'audio')+and+trashed=false&spaces=drive&fields=nextPageToken,files(id,+name,+size,+mimeType)&key=AIzaSyCMsksSn6-1FzYhN49uDAzN83HGvFVXqaU"
        YSFilesMetadataDownloader.downloadFilesList(for: url)
        { filesDictionary, error in
            if let err = error
            {
                let yserror = err as! YSError
                //TODO: search local copy
                completionHandler([], yserror)
                //YSDatabaseManager.files(for: self.currentFolder, yserror, completionHandler)
                return
            }
            //YSDatabaseManager.save(filesDictionary: filesDictionary!, self.currentFolder, completionHandler)
        }
    }
    
    func download(for file: YSDriveFileProtocol) -> YSDownloadProtocol?
    {
        return YSAppDelegate.appDelegate().fileDownloader?.download(for: file)
    }
    
    func download(_ file : YSDriveFileProtocol)
    {
        YSAppDelegate.appDelegate().fileDownloader?.download(file: file)
    }
    
    func stopDownload(_ file : YSDriveFileProtocol)
    {
        YSAppDelegate.appDelegate().fileDownloader?.cancelDownloading(file: file)
    }
}
