//
//  YSDriveViewModelViewDelegate.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/22/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation

protocol YSDriveViewModelViewDelegate: class
{
    func filesDidChange(viewModel: YSDriveViewModelProtocol)
    func metadataDownloadStatusDidChange(viewModel: YSDriveViewModelProtocol)
    func errorDidChange(viewModel: YSDriveViewModelProtocol, error: YSErrorProtocol)
    func downloadErrorDidChange(viewModel: YSDriveViewModelProtocol, error: YSErrorProtocol, download : YSDownloadProtocol)
    func downloadErrorDidChange(viewModel: YSDriveViewModelProtocol, error: YSErrorProtocol, file : YSDriveFileProtocol)
    func reloadFile(at index: Int, viewModel: YSDriveViewModelProtocol)
    func reloadFileDownload(at index: Int, viewModel: YSDriveViewModelProtocol)
}

protocol YSDriveViewModelCoordinatorDelegate: class
{
    func driveViewModelDidSelectFile(_ viewModel: YSDriveViewModelProtocol, file: YSDriveFileProtocol)
    func driveViewModelDidRequestedLogin()
    func driveViewModelDidFinish()
    func driveViewControllerDidRequestedSearch()
    func driveViewControllerDidDeletedFiles()
}

protocol YSDriveViewModelProtocol
{
    var model: YSDriveModelProtocol? { get set }
    var viewDelegate: YSDriveViewModelViewDelegate? { get set }
    var coordinatorDelegate: YSDriveViewModelCoordinatorDelegate? { get set}
    var numberOfFiles: Int { get }
    var isFilesPresent: Bool { get }
    var isLoggedIn: Bool { get }
    var isDownloadingMetadata: Bool { get }
    var error : YSErrorProtocol { get }
    
    func file(at index: Int) -> YSDriveFileProtocol?
    func download(for file: YSDriveFileProtocol) -> YSDownloadProtocol?
    func useFile(at index: Int)
    func loginToDrive()
    func removeDownloads()
    func getFiles(_ completion: @escaping FilesCompletionHandler)
    func driveViewControllerDidFinish()
    func driveViewControllerDidRequestedSearch()
    func download(_ file : YSDriveFileProtocol)
    func stopDownloading(_ file : YSDriveFileProtocol)
    func index(of file : YSDriveFileProtocol) -> Int
    func deleteDownloadsFor(_ indexes : [IndexPath])
    func downloadFilesFor(_ indexes : [IndexPath])
    //TODO: add function for refreshing files not get files
    func getNextPartOfFiles()
}
