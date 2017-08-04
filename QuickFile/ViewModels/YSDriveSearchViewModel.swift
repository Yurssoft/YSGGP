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
            nextPageToken = nil
            getFiles(sectionType: sectionType, searchTerm: searchTerm, completion: { (files) in
                self.files = files
            })
        }
    }
    
    fileprivate var files: [YSDriveFileProtocol] = []
    {
        didSet
        {
            viewDelegate?.filesDidChange(viewModel: self)
        }
    }
    
    //TODO:check in last moment
    fileprivate var nextPageToken: String?
    
    var sectionType: YSSearchSectionType = YSSearchSectionType(rawValue: YSSearchSectionType.all.rawValue)!
    
    func subscribeToDownloadingProgress()
    {
        coordinatorDelegate?.subscribeToDownloadingProgress()
    }
    
    func getNextPartOfFiles()
    {
        guard nextPageToken != nil, !isDownloadingMetadata else { return }
        getFiles(sectionType: sectionType, searchTerm: searchTerm, completion: { (files) in
            self.files.append(contentsOf: files)
        })
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
    
    //TODO: check all completion for weak
    func getFiles(sectionType: YSSearchSectionType, searchTerm: String, completion: @escaping FilesCompletionHandler)
    {
        if isDownloadingMetadata
        {
            return
        }
        self.sectionType = sectionType
        isDownloadingMetadata = true
        model?.getFiles(for: searchTerm, sectionType: sectionType, nextPageToken: nextPageToken)
        { (files, nextPageToken, error) in
            completion(files)
            self.nextPageToken = nextPageToken
            self.isDownloadingMetadata = false
            self.error = error!
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
        DispatchQueue.main.async
        {
            self.viewDelegate?.filesDidChange(viewModel: self)
        }
    }

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
