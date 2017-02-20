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
    func errorDidChange(viewModel: YSDriveSearchViewModelProtocol, error: YSErrorProtocol)
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
    
    func file(at index: Int) -> YSDriveFileProtocol?
    func download(for file: YSDriveFileProtocol) -> YSDownloadProtocol?
    func useFile(at index: Int)
    func getFiles(completion: @escaping CompletionHandler)
    func searchViewControllerDidFinish()
    func download(_ file : YSDriveFileProtocol)
    func stopDownloading(_ file : YSDriveFileProtocol)
    func index(of file : YSDriveFileProtocol) -> Int
}
