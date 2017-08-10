//
//  YSPlaylistViewModelProtocol.swift
//  YSGGP
//
//  Created by Yurii Boiko on 12/6/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation

protocol YSPlaylistViewModelViewDelegate: class
{
    func filesDidChange(viewModel: YSPlaylistViewModelProtocol)
    func errorDidChange(viewModel: YSPlaylistViewModelProtocol, error: YSErrorProtocol)
}

protocol YSPlaylistViewModelCoordinatorDelegate: class
{
    func playlistViewModelDidSelectFile(_ viewModel: YSPlaylistViewModelProtocol, file: YSDriveFileProtocol)
}

protocol YSPlaylistViewModelProtocol
{
    var model: YSPlaylistAndPlayerModelProtocol? { get set }
    weak var viewDelegate: YSPlaylistViewModelViewDelegate? { get set }
    weak var coordinatorDelegate: YSPlaylistViewModelCoordinatorDelegate? { get set}
    var numberOfFolders: Int { get }
    var error : YSErrorProtocol { get }
    
    func numberOfFiles(in folder: Int) -> Int
    func file(at index: Int, folderIndex: Int) -> YSDriveFileProtocol?
    func folder(at index: Int) -> YSDriveFileProtocol?
    func useFile(at folder: Int, file: Int)
    func removeDownloads()
    func getFiles(completion: @escaping ErrorCompletionHandler)
    func indexPath(of file : YSDriveFileProtocol) -> IndexPath
}
