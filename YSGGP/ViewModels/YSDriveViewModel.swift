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
            files = []
            if !isLoggedIn
            {
                return
            }
            isDownloadingMetadata = true
            model?.getFiles()
            { (files, error) in
                self.isDownloadingMetadata = false
                self.files = files
                self.error = error!
            }
        }
    }
    
    var numberOfFiles: Int
    {
        return files.count
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
    
    func getFiles(completion: @escaping CompletionHandler)
    {
        isDownloadingMetadata = true
        model?.getFiles()
            { (files, error) in
            self.isDownloadingMetadata = false
            self.files = files
            self.error = error!
            completion(error)
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
                //TODO: after removing update player and playlist
                file.removeLocalFile()
                files[indexPath.row] = file
            }
        }
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
}

extension YSDriveViewModel : YSDriveFileDownloaderDelegate
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
}
