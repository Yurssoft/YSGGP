//
//  YSDriveSearchViewModel.swift
//  YSGGP
//
//  Created by Yurii Boiko on 2/20/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import Foundation

enum YSSearchSectionType : String
{
    case all = "All"
    case files = "Files"
    case folders = "Folders"
}

protocol YSDriveSearchViewModelViewDelegate: class
{
    func filesDidChange(viewModel: YSDriveSearchViewModelProtocol)
    func metadataDownloadStatusDidChange(viewModel: YSDriveSearchViewModelProtocol)
    func errorDidChange(viewModel: YSDriveSearchViewModelProtocol, error: YSErrorProtocol)
    func downloadErrorDidChange(viewModel: YSDriveSearchViewModelProtocol, error: YSErrorProtocol, file : YSDriveFileProtocol)
    func downloadErrorDidChange(viewModel: YSDriveSearchViewModelProtocol, error: YSErrorProtocol, download : YSDownloadProtocol)
    func reloadFileDownload(at index: Int, viewModel: YSDriveSearchViewModelProtocol)
}

protocol YSDriveSearchViewModelCoordinatorDelegate: class
{
    func searchViewModelDidSelectFile(_ viewModel: YSDriveSearchViewModelProtocol, file: YSDriveFileProtocol)
    func searchViewModelDidFinish()
    func subscribeToDownloadingProgress()
}

protocol YSDriveSearchViewModelProtocol
{
    var model: YSDriveSearchModelProtocol? { get set }
    var viewDelegate: YSDriveSearchViewModelViewDelegate? { get set }
    var coordinatorDelegate: YSDriveSearchViewModelCoordinatorDelegate? { get set }
    var numberOfFiles: Int { get }
    var isDownloadingMetadata: Bool { get }
    var error : YSErrorProtocol { get }
    var searchTerm : String { get set }
    var sectionType: YSSearchSectionType { get set }
    
    func subscribeToDownloadingProgress()
    func file(at index: Int) -> YSDriveFileProtocol?
    func download(for file: YSDriveFileProtocol) -> YSDownloadProtocol?
    func useFile(at index: Int)
    func refreshFiles(_ completion: @escaping () -> Swift.Void)
    func getNextPartOfFiles(_ completion: @escaping () -> Swift.Void)
    func searchViewControllerDidFinish()
    func download(_ file : YSDriveFileProtocol)
    func stopDownloading(_ file : YSDriveFileProtocol)
    func index(of file : YSDriveFileProtocol) -> Int
}
