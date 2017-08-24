//
//  YSDriveSearchViewModel.swift
//  YSGGP
//
//  Created by Yurii Boiko on 2/20/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import Foundation
import SwiftMessages

class YSDriveSearchViewModel: YSDriveSearchViewModelProtocol
{
    var model: YSDriveSearchModelProtocol?
    {
        didSet
        {
            refreshFiles { }
        }
    }
    
    weak var viewDelegate: YSDriveSearchViewModelViewDelegate?
    weak var coordinatorDelegate: YSDriveSearchViewModelCoordinatorDelegate?
    
    var numberOfFiles: Int
    {
        return files.count
    }
    
    var isDownloadingMetadata: Bool = false
    {
        didSet
        {
            viewDelegate?.metadataDownloadStatusDidChange(viewModel: self)
        }
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
    
    var searchTerm : String = ""
    {
        didSet
        {
            refreshFiles { }
        }
    }
    
    fileprivate var files: [YSDriveFileProtocol] = []
    {
        didSet
        {
            viewDelegate?.filesDidChange(viewModel: self)
        }
    }
    
    fileprivate var nextPageToken: String?
    
    var sectionType: YSSearchSectionType = YSSearchSectionType(rawValue: YSSearchSectionType.all.rawValue)!
    {
        didSet
        {
            refreshFiles { }
        }
    }
    
    var allPagesDownloaded : Bool = false
    
    func subscribeToDownloadingProgress()
    {
        coordinatorDelegate?.subscribeToDownloadingProgress()
    }
    
    func refreshFiles(_ completion: @escaping () -> Swift.Void)
    {
        guard !isDownloadingMetadata else
        {
            completion()
            return
        }
        nextPageToken = nil
        getFiles
        {[weak self]  (files) in
            self?.files = files
            self?.callCompletion(completion)
        }
    }
    
    func getNextPartOfFiles(_ completion: @escaping () -> Swift.Void)
    {
        guard nextPageToken != nil, !isDownloadingMetadata else
        {
            completion()
            return
        }
        getFiles
        {[weak self]  (files) in
            self?.files.append(contentsOf: files)
            self?.callCompletion(completion)
        }
    }
    
    func file(at index: Int) -> YSDriveFileProtocol?
    {
        if files.count > index
        {
            return files[index]
        }
        viewDelegate?.filesDidChange(viewModel: self)
        return YSDriveFile()
    }
    
    func download(for file: YSDriveFileProtocol) -> YSDownloadProtocol?
    {
        return model?.download(for: file)
    }
    
    func useFile(at index: Int)
    {
        guard let coordinatorDelegate = coordinatorDelegate, index < files.count else { return }
        coordinatorDelegate.searchViewModelDidSelectFile(self, file: files[index])
    }

    fileprivate func getFiles(_ completion: @escaping FilesCompletionHandler)
    {
        isDownloadingMetadata = true
        model?.getFiles(for: searchTerm, sectionType: sectionType, nextPageToken: nextPageToken)
        {[weak self] (files, nextPageToken, error) in
            self?.nextPageToken = nextPageToken
            self?.isDownloadingMetadata = false
            self?.error = error!
            self?.allPagesDownloaded = nextPageToken == nil
            completion(files)
        }
    }
    
    func searchViewControllerDidFinish()
    {
        coordinatorDelegate?.searchViewModelDidFinish()
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
}

extension YSDriveSearchViewModel : YSUpdatingDelegate
{
    internal func filesDidChange()
    {
        self.viewDelegate?.filesDidChange(viewModel: self)
    }

    func downloadDidChange(_ download : YSDownloadProtocol,_ error: YSErrorProtocol?)
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
