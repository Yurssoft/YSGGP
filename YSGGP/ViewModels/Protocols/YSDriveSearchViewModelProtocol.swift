//
//  YSDriveSearchViewModel.swift
//  YSGGP
//
//  Created by Yurii Boiko on 2/20/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import Foundation

protocol YSDriveSearchViewModelViewDelegate: class
{
    func filesDidChange(viewModel: YSDriveSearchViewModelProtocol)
    func metadataNextPageFilesDownloadingStatusDidChange(viewModel: YSDriveSearchViewModelProtocol)
    func errorDidChange(viewModel: YSDriveSearchViewModelProtocol, error: YSErrorProtocol)
    func downloadErrorDidChange(viewModel: YSDriveSearchViewModelProtocol, error: YSErrorProtocol, file : YSDriveFileProtocol)
    func downloadErrorDidChange(viewModel: YSDriveSearchViewModelProtocol, error: YSErrorProtocol, download : YSDownloadProtocol)
    func reloadFileDownload(at index: Int, viewModel: YSDriveSearchViewModelProtocol)
}

protocol YSDriveSearchViewModelCoordinatorDelegate: class
{
    func searchViewModelDidSelectFile(_ viewModel: YSDriveSearchViewModelProtocol, file: YSDriveFileProtocol)
    func searchViewModelDidFinish()
}

protocol YSDriveSearchViewModelProtocol
{
    var model: YSDriveSearchModelProtocol? { get set }
    var viewDelegate: YSDriveSearchViewModelViewDelegate? { get set }
    var coordinatorDelegate: YSDriveSearchViewModelCoordinatorDelegate? { get set}
    var numberOfFiles: Int { get }
    var isDownloadingMetadata: Bool { get }
    var error : YSErrorProtocol { get }
    var searchTerm : String { get set }
    var isDownloadingNextPageOfFiles: Bool { get }
    
    func getNextPartOfFiles()
    func file(at index: Int) -> YSDriveFileProtocol?
    func download(for file: YSDriveFileProtocol) -> YSDownloadProtocol?
    func useFile(at index: Int)
    func getFiles(completion: @escaping CompletionHandler)
    func searchViewControllerDidFinish()
    func download(_ file : YSDriveFileProtocol)
    func stopDownloading(_ file : YSDriveFileProtocol)
    func index(of file : YSDriveFileProtocol) -> Int
}
