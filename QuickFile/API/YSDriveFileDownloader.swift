//
//  YSDriveFileDownloader.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/26/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit
import SwiftMessages
import Firebase
import ReachabilitySwift
import SwiftyBeaver

class YSDriveFileDownloader : NSObject
{
    fileprivate var downloads : [String : YSDownloadProtocol] = [String : YSDownloadProtocol]()
    fileprivate var session : URLSession
    fileprivate var sessionQueue : OperationQueue
    fileprivate var reachability : Reachability = Reachability()!
    
    required override init()
    {
        session = URLSession()
        sessionQueue = OperationQueue()
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.yurssoft.YSGGP.drive_background_file_downloader_session")
        sessionQueue.qualityOfService = .background
        sessionQueue.name = "drive_background_file_downloader_delegate_queue"
        let backgroundSession = URLSession(configuration: configuration, delegate: self, delegateQueue: sessionQueue)
        session = backgroundSession
        reachability.whenReachable =
        { reachability in
            self.downloadNextFile()
        }
        try? reachability.startNotifier()
    }
    
    func downloadNextFile()
    {
        let activeDownloads = downloads.values.filter
        {
            if case .downloading(_) = $0.downloadStatus
            {
                return true
            }
            return false
        }
        if downloads.count > 0 && activeDownloads.count == 0, var download = downloads.first?.value
        {
            if case .downloading(_) = download.downloadStatus
            {
                return
            }
            let url = download.file.fileUrl()
            let reqURL = URL.init(string: url)
            let request = URLRequest.init(url: reqURL!)
            YSCredentialManager.shared.addAccessTokenHeaders(request)
            {  request, error in
                if error != nil
                {
                    return
                }
                let downloadTask = self.session.downloadTask(with: request)
                download.downloadTask = downloadTask
                downloadTask.resume()
                download.downloadStatus = .downloading(progress: 0.0)
                self.downloads[url] = download
                YSAppDelegate.appDelegate().downloadsDelegate?.downloadDidChange(download, nil)
            }
        }
    }
    
    func download(for file: YSDriveFileProtocol) -> YSDownloadProtocol?
    {
        return downloads[file.fileUrl()]
    }
    
    func download(file: YSDriveFileProtocol)
    {
        if !file.isAudio
        {
            downloadFolder(file: file)
            return
        }
        if file.localFileExists() || downloads[file.fileUrl()] != nil
        {
            let log = SwiftyBeaver.self
            log.error("Error downloading file:  local file exists or file is already in downloading queue")
            return
        }
        var download = YSDownload(file: file)
        download.downloadStatus = .pending
        downloads[file.fileUrl()] = download
        YSAppDelegate.appDelegate().downloadsDelegate?.downloadDidChange(download, nil)
        downloadNextFile()
    }
    
    func downloadFolder(file: YSDriveFileProtocol)
    {
        let folder = YSFolder()
        folder.folderID = file.fileDriveIdentifier
        folder.folderName = file.fileName
        
        YSDatabaseManager.offlineFiles(folder: folder, YSError()) { (filesToDownload, _, _) in
            for fileToDownload in filesToDownload
            {
                if fileToDownload.isAudio
                {
                    self.download(file: fileToDownload)
                }
            }
        }
    }
    
    func cancelDownloading(file: YSDriveFileProtocol)
    {
        if let download = downloads[file.fileUrl()]
        {
            download.downloadTask?.cancel()
            YSAppDelegate.appDelegate().downloadsDelegate?.downloadDidChange(download, nil)
            downloads[file.fileUrl()] = nil
            downloadNextFile()
        }
    }
}

extension YSDriveFileDownloader: URLSessionDelegate
{
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        if let appDelegate = UIApplication.shared.delegate as? YSAppDelegate
        {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler
            {
                appDelegate.backgroundSessionCompletionHandler = nil
                DispatchQueue.main.async
                {
                    completionHandler()
                }
            }
        }
    }
}

extension YSDriveFileDownloader: URLSessionDownloadDelegate
{
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        if let url = downloadTask.originalRequest?.url?.absoluteString, var download = downloads[url]
        {
            if let err = YSNetworkResponseManager.validateDownloadTask(downloadTask.response, error: nil, fileName: download.file.fileName)
            {
                YSAppDelegate.appDelegate().downloadsDelegate?.downloadDidChange(download, err)
                downloads[url] = nil
                return
            }
            let fileManager = FileManager.default
            
            try? fileManager.removeItem(at: download.file.localFilePath()!)
            
            do
            {
                try fileManager.copyItem(at: location, to: download.file.localFilePath()!)
                //YSDatabaseManager.update(file: download.file)
            }
            catch let error as NSError
            {
                try? fileManager.removeItem(at: download.file.localFilePath()!)
                let log = SwiftyBeaver.self
                log.error("Could not copy file to disk: \(error.localizedDescription)")
                
                let errorMessage = YSError(errorType: YSErrorType.couldNotDownloadFile, messageType: Theme.error, title: "Error", message: "Could not copy file \(download.file.fileName)", buttonTitle: "Try again", debugInfo: error.localizedDescription)
                
                YSAppDelegate.appDelegate().downloadsDelegate?.downloadDidChange(download, errorMessage)
                downloads[url] = nil
                return
            }
            if download.file.localFileExists()
            {
                YSAppDelegate.appDelegate().filesOnDisk.append(download.file.fileDriveIdentifier)
            }
            
            //TODO: multicast delegate?
            YSAppDelegate.appDelegate().playlistDelegate?.downloadDidChange(download, nil)
            YSAppDelegate.appDelegate().playerDelegate?.downloadDidChange(download, nil)
            YSAppDelegate.appDelegate().downloadsDelegate?.downloadDidChange(download, nil)
            downloads[url] = nil
            downloadNextFile()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        if let url = downloadTask.originalRequest?.url?.absoluteString, var download = downloads[url]
        {
            let progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
            download.downloadStatus = .downloading(progress: progress)
            let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: ByteCountFormatter.CountStyle.binary)
            download.totalSize = totalSize
            downloads[url] = download
            YSAppDelegate.appDelegate().downloadsDelegate?.downloadDidChange(download, nil)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        if let error = error, let url = task.originalRequest?.url?.absoluteString, var download = downloads[url]
        {
            if error.localizedDescription.contains("cancelled") || error.localizedDescription.contains("connection was lost") || error.localizedDescription.contains("No such file or directory")
            {
                let url = download.file.fileUrl()
                download.downloadStatus = .pending
                downloads[url] = download
                downloadNextFile()
                return
            }
            var yserror : YSErrorProtocol
            yserror = YSError(errorType: YSErrorType.couldNotDownloadFile, messageType: Theme.error, title: "Error", message: "Couldn't download \(download.file.fileName)", buttonTitle: "Try Again", debugInfo: error.localizedDescription)
            YSAppDelegate.appDelegate().downloadsDelegate?.downloadDidChange(download, yserror)
            downloads[download.file.fileUrl()] = nil
        }
    }
}

