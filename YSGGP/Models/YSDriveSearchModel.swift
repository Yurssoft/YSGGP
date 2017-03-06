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
    func getFiles(for searchTerm: String, sectionType: YSSearchSectionType, nextPageToken: String, _ completionHandler: @escaping DriveSearchCompletionHandler)
    {
        var url = "\(YSConstants.kDriveAPIEndpoint)files?"
        if nextPageToken.characters.count > 0
        {
            let encodedNextPageToken = CFURLCreateStringByAddingPercentEscapes(
                nil,
                nextPageToken as CFString!,
                nil,
                "!'();:@&=+$,/?%#[]" as CFString!,
                CFStringBuiltInEncodings.ASCII.rawValue
            )!
            url.append("pageToken=\(encodedNextPageToken)&")
        }
        switch sectionType
        {
        case .all:
            url.append("corpus=user&orderBy=folder,name&pageSize=20&q=SEARCH_CONTAINS(mimeType+contains+'folder'+or+mimeType+contains+'audio')+and+trashed=false&spaces=drive&fields=nextPageToken,files(id,+name,+size,+mimeType)&key=AIzaSyCMsksSn6-1FzYhN49uDAzN83HGvFVXqaU")
            break
        case .files:
            url.append("corpus=user&orderBy=folder,name&pageSize=20&q=SEARCH_CONTAINSmimeType+contains+'audio'+and+trashed=false&spaces=drive&fields=nextPageToken,files(id,+name,+size,+mimeType)&key=AIzaSyCMsksSn6-1FzYhN49uDAzN83HGvFVXqaU")
            break
        case .folders:
            url.append("corpus=user&orderBy=folder,name&pageSize=20&q=SEARCH_CONTAINSmimeType+contains+'folder'+and+trashed=false&spaces=drive&fields=nextPageToken,files(id,+name,+size,+mimeType)&key=AIzaSyCMsksSn6-1FzYhN49uDAzN83HGvFVXqaU")
            break
        }
        let searchTermClean = searchTerm.replacingOccurrences(of: " ", with: "")
        if searchTermClean.characters.count > 0
        {
            let searchTerm = searchTerm.replacingOccurrences(of: " ", with: "+")
            let contains = "name+contains+'\(searchTerm)'+and+"
            url = url.replacingOccurrences(of: "SEARCH_CONTAINS", with: contains)
        }
        else
        {
            url = url.replacingOccurrences(of: "SEARCH_CONTAINS", with: "")
        }
        YSFilesMetadataDownloader.downloadFilesList(for: url)
        { filesDictionary, error in
            if let err = error
            {
                let yserror = err as! YSError
                //TODO: search local database as section
                completionHandler([], "", yserror)
                return
            }
            guard let filesDictionary = filesDictionary else { return completionHandler([], "", YSError()) }
            var ysFiles = [YSDriveFileProtocol]()
            var nextPageToken = String()
            for fileKey in filesDictionary.keys
            {
                switch fileKey
                {
                case "nextPageToken":
                    let token = filesDictionary[fileKey] as! String
                    nextPageToken = token
                    continue
                    
                    case "files":
                    
                    let files = filesDictionary[fileKey] as! [Any]
                    
                    for file in files
                    {
                        let fileDict = file as! [String : Any]
                        
                        let ysFile = YSDriveFile.init(fileName: fileDict["name"] as! String?,
                                                      fileSize: fileDict["size"] as! String?,
                                                      mimeType: fileDict["mimeType"] as! String?,
                                                      fileDriveIdentifier: fileDict["id"] as! String?,
                                                      folderName: "",
                                                      folderID: "",
                                                      playedTime : "",
                                                      isPlayed : false,
                                                      isCurrentlyPlaying : false)
                        ysFiles.append(ysFile)
                    }
                    continue
                    
                    default:
                    break
                }
            }
            completionHandler(ysFiles, nextPageToken, YSError())
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
