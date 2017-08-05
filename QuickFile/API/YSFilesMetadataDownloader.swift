//
//  YSFilesMetadataDownloader.swift
//  YSGGP
//
//  Created by Yurii Boiko on 11/16/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import SwiftMessages
import SystemConfiguration

typealias FilesListMetadataDownloadedCompletionHandler = (_ filesDictionary : [String : Any]?,_ error: YSErrorProtocol?) -> Swift.Void

class YSFilesMetadataDownloader
{
    class func downloadFilesList(for requestURL: String, _ completionHandler: FilesListMetadataDownloadedCompletionHandler? = nil)
    {
        let reqURL = URL.init(string: requestURL)
        let request = URLRequest.init(url: reqURL!)
        YSCredentialManager.shared.addAccessTokenHeaders(request)
        {  request, error in
            if var err = error
            {
                //TODO: remove duplicated code
                if err.debugInfo.contains("connection appears to be offline")
                {
                    err.update(errorType: .couldNotGetFileList, messageType: .warning, title: "Warning", message: YSConstants.kNoInternetMessage)
                }
                else if err.errorType == YSErrorType.notLoggedInToDrive
                {
                    completionHandler!(["" : ["": NSNull()]], err)
                    return
                }
                else
                {
                    err.update(errorType: .couldNotGetFileList, messageType: .warning, title: "Warning", message: "Could not get file list")
                }
                completionHandler!(["" : ["": NSNull()]], err)
                return
            }
            let task = URLSession.shared.dataTask(with: request)
            { data, response, error in
                if var err = YSNetworkResponseManager.validate(response, error: error)
                {
                    if err.errorType == YSErrorType.notLoggedInToDrive
                    {
                        completionHandler!(["" : ["": NSNull()]], err)
                        return
                    }
                    else if err.debugInfo.contains("connection appears to be offline")
                    {
                        err.update(errorType: .couldNotGetFileList, messageType: .warning, title: "Warning", message: YSConstants.kNoInternetMessage)
                    }
                    else
                    {
                        err.update(errorType: .couldNotGetFileList, messageType: .warning, title: "Warning", message: "Could not get file list")
                    }
                    completionHandler!(["" : ["": NSNull()]], err)
                    return
                }
                let dict = YSNetworkResponseManager.convertToDictionary(from: data!)
                completionHandler!(dict, nil)
            }
            task.resume()
        }
    }
}
