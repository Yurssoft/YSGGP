//
//  YSDriveViewModel.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/22/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import SwiftMessages

class YSDriveViewModel: YSDriveViewModelProtocol
{
    var isLoggedIn: Bool
    {
       return (model?.isLoggedIn)!
    }
    
    var isFilesPresent: Bool
    {
        return !files.isEmpty
    }
    
    var error : YSErrorProtocol = YSError()
    {
        didSet
        {
            if !error.isEmpty()
            {
                viewDelegate?.errorDidChange(viewModel: self, error: error)
            }
        }
    }

    weak var viewDelegate: YSDriveViewModelViewDelegate?
    {
        didSet
        {
            viewDelegate?.metadataDownloadStatusDidChange(viewModel: self)
        }
    }
    
    var coordinatorDelegate: YSDriveViewModelCoordinatorDelegate?
    
    fileprivate var files: [YSDriveFileProtocol] = []
    {
        didSet
        {
            viewDelegate?.filesDidChange(viewModel: self)
        }
    }
    
    var isDownloadingMetadata : Bool = false
    {
        didSet
        {
            viewDelegate?.metadataDownloadStatusDidChange(viewModel: self)
        }
    }
    
    var model: YSDriveModelProtocol?
    {
        didSet
        {
            refreshFiles { }
        }
    }
    
    var numberOfFiles: Int
    {
        return files.count
    }
    
    fileprivate var pageTokens: [String] = [YSConstants.kFirstPageToken]
    var allPagesDownloaded : Bool = false
    {
        didSet
        {
            viewDelegate?.allPagesDownloaded(viewModel: self)
        }
    }
    
    func file(at index: Int) -> YSDriveFileProtocol?
    {
        if files.count > index
        {
            return files[index]
        }
        return nil
    }
    
    func download(for file: YSDriveFileProtocol) -> YSDownloadProtocol?
    {
        return model?.download(for: file)
    }
    
    func useFile(at index: Int)
    {
        if let coordinatorDelegate = coordinatorDelegate, index < files.count
        {
            coordinatorDelegate.driveViewModelDidSelectFile(self, file: files[index])
        }
    }
    
    func loginToDrive()
    {
        coordinatorDelegate?.driveViewModelDidRequestedLogin()
    }
    
    func removeDownloads()
    {
        files.removeAll()
        viewDelegate?.filesDidChange(viewModel: self)
    }
    
    fileprivate func getFiles(_ completion: @escaping FilesCompletionHandler)
    {
        isDownloadingMetadata = true
        model?.getFiles(pageToken: pageTokens.first!, nextPageToken: pageTokens.count > 1 ? pageTokens.last : nil)
        { [weak self] (files, error, nextPageToken) in
            self?.isDownloadingMetadata = false
            completion(files)
            self?.error = error!
            guard let token = nextPageToken else
            {
                self?.allPagesDownloaded = true
                return
            }
            self?.pageTokens.append(token)
        }
    }
    
    func driveViewControllerDidFinish()
    {
        coordinatorDelegate?.driveViewModelDidFinish()
    }
    
    func driveViewControllerDidRequestedSearch()
    {
        coordinatorDelegate?.driveViewControllerDidRequestedSearch()
    }
    
    func download(_ file : YSDriveFileProtocol)
    {
        if !isLoggedIn
        {
            showNotLoggedInMessage()
            return
        }
        model?.download(file)
    }
    
    func stopDownloading(_ file: YSDriveFileProtocol)
    {
        model?.stopDownload(file)
    }
    
    func index(of file : YSDriveFileProtocol) -> Int
    {
        if let index = files.index(where: {$0.fileDriveIdentifier == file.fileDriveIdentifier})
        {
            return index
        }
        return 0
    }
    
    func deleteDownloadsFor(_ indexes : [IndexPath])
    {
        for indexPath in indexes
        {
            let file = files[indexPath.row]
            if file.isAudio
            {
                stopDownloading(file)
                file.removeLocalFile()
                files[indexPath.row] = file
            }
        }
        coordinatorDelegate?.driveViewControllerDidDeletedFiles()
        viewDelegate?.filesDidChange(viewModel: self)
    }
    
    func downloadFilesFor(_ indexes : [IndexPath])
    {
        for indexPath in indexes
        {
            let file = files[indexPath.row]
            download(file)
        }
    }
    
    func refreshFiles(_ completion: @escaping () -> Swift.Void)
    {
        if !isLoggedIn
        {
            callCompletion(completion)
            showNotLoggedInMessage()
            return
        }
        guard !isDownloadingMetadata else
        {
            callCompletion(completion)
            return
        }
        pageTokens = [YSConstants.kFirstPageToken]
        getFiles
        {[weak self]  files in
            self?.files = files
            self?.callCompletion(completion)
        }
    }
    
    func getNextPartOfFiles(_ completion: @escaping () -> Swift.Void)
    {
        if !isLoggedIn
        {
            callCompletion(completion)
            showNotLoggedInMessage()
            return
        }
        guard !isDownloadingMetadata, pageTokens.count > 1 else
        {
            callCompletion(completion)
            return
        }
        getFiles
        {[weak self]  (files) in
            self?.files.append(contentsOf: files)
            self?.callCompletion(completion)
        }
    }
    
    func callCompletion(_ completion: @escaping () -> Swift.Void)
    {
        DispatchQueue.main.async
        {
            completion()
        }
    }
    
    fileprivate func showNotLoggedInMessage()
    {
        let errorMessage = YSError(errorType: YSErrorType.notLoggedInToDrive, messageType: Theme.warning, title: "Warning", message: "Could not get list, please login", buttonTitle: "Login", debugInfo: "")
        error = errorMessage
    }
}

extension YSDriveViewModel : YSUpdatingDelegate
{
    func downloadDidChange(_ download : YSDownloadProtocol,_ error: YSErrorProtocol?)
    {
        DispatchQueue.main.async
        {
            if let error = error
            {
                self.viewDelegate?.downloadErrorDidChange(viewModel: self, error: error, download: download)
            }
            let index = self.files.index(where: {$0.fileDriveIdentifier == download.file.fileDriveIdentifier})
            guard let indexx = index, self.files.count > indexx else { return }
            self.viewDelegate?.reloadFileDownload(at: indexx, viewModel: self)
        }
    }
    
    func filesDidChange()
    {
        DispatchQueue.main.async
        {
            self.viewDelegate?.filesDidChange(viewModel: self)
        }
    }
}
