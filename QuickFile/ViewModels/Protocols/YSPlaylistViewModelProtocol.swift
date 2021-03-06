//
//  YSPlaylistViewModelProtocol.swift
//  YSGGP
//
//  Created by Yurii Boiko on 12/6/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation

protocol YSPlaylistViewModelViewDelegate: class {
    func filesDidChange(viewModel: YSPlaylistViewModelProtocol)
    func fileDidChange(viewModel: YSPlaylistViewModelProtocol)
    func errorDidChange(viewModel: YSPlaylistViewModelProtocol, error: YSErrorProtocol)
    func scrollToCurrentlyPlayingFile(at indexPath: IndexPath)
}

protocol YSPlaylistViewModelCoordinatorDelegate: class {
    func playlistViewModelDidSelectFile(_ viewModel: YSPlaylistViewModelProtocol, file: YSDriveFileProtocol)
}

protocol YSPlaylistViewModelProtocol {
    var model: YSPlaylistAndPlayerModelProtocol? { get set }
    var viewDelegate: YSPlaylistViewModelViewDelegate? { get set }
    var coordinatorDelegate: YSPlaylistViewModelCoordinatorDelegate? { get set}
    var numberOfFolders: Int { get }
    var error: YSErrorProtocol { get }

    func viewIsLoadedAndReadyToDisplay(_ completion: @escaping CompletionHandler)
    func numberOfFiles(in folder: Int) -> Int
    func file(at index: Int, folderIndex: Int) -> YSDriveFileProtocol?
    func folder(at index: Int) -> YSDriveFileProtocol?
    func useFile(at folder: Int, file: Int)
    func removeDownloads()
    func getFiles(completion: @escaping ErrorCH)
    func indexPath(of file: YSDriveFileProtocol) -> IndexPath
}
