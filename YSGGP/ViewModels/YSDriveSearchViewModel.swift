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
            nextPageToken = ""
            getFiles
                { (error) in
                self.viewDelegate?.filesDidChange(viewModel: self)
            }
        }
    }
    
    fileprivate var files: [YSDriveFileProtocol] = []
        {
        didSet
        {
            viewDelegate?.filesDidChange(viewModel: self)
        }
    }
    
    fileprivate var nextPageToken: String = ""
    
    
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
        guard let coordinatorDelegate = coordinatorDelegate, index < files.count else { return }
        coordinatorDelegate.searchViewModelDidSelectFile(self, file: files[index])
    }
    
    func getFiles(completion: @escaping CompletionHandler)
    {
        isDownloadingMetadata = true
        model?.getFiles(for: searchTerm, nextPageToken: nextPageToken)
            { (files, nextPageToken, error) in
                self.nextPageToken = nextPageToken
                self.isDownloadingMetadata = false
                self.files = files
                self.error = error!
                completion(error)
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
