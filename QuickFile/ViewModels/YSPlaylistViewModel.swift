//
//  YSPlaylistViewModel.swift
//  YSGGP
//
//  Created by Yurii Boiko on 12/6/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation

class YSPlaylistViewModel: YSPlaylistViewModelProtocol {
    func viewIsLoadedAndReadyToDisplay(_ completion: @escaping CompletionHandler) {
        getFiles { (_) in
            completion()
        }
    }
    
    var model: YSPlaylistAndPlayerModelProtocol?

    fileprivate var files = [YSDriveFileProtocol]() {
        didSet {
            folders = selectFolders()
        }
    }

    var folders = [YSDriveFileProtocol]()

    weak var viewDelegate: YSPlaylistViewModelViewDelegate?

    weak var coordinatorDelegate: YSPlaylistViewModelCoordinatorDelegate?

    func numberOfFiles(in folder: Int) -> Int {
        guard folders.count > folder else { return 0 }
        let folderFile = folders[folder]
        let filesInFolder = files.filter { $0.folder.folderID == folderFile.id && $0.isAudio }
        return filesInFolder.count
    }

    var numberOfFolders: Int {
        return folders.count
    }

    func selectFolders() -> [YSDriveFileProtocol] {
        let folders = files.filter {
                let folderFile = $0
                if !folderFile.isAudio {
                    let filesInFolder = files.filter { $0.folder.folderID == folderFile.id && $0.isAudio }
                    return filesInFolder.count > 0
                } else {
                    return false
                }
        }
        return folders
    }

    var error: YSErrorProtocol = YSError() {
        didSet {
            if !error.isEmpty() {
                viewDelegate?.errorDidChange(viewModel: self, error: error)
            }
        }
    }

    func file(at index: Int, folderIndex: Int) -> YSDriveFileProtocol? {
        guard folders.count > folderIndex else { return nil }
        let folderFile = folders[folderIndex]
        let filesInFolder = files.filter { $0.folder.folderID == folderFile.id && $0.isAudio }
        guard filesInFolder.count > index else { return nil }
        let file = filesInFolder[index]
        return file
    }

    func folder(at index: Int) -> YSDriveFileProtocol? {
        guard folders.count > index else { return nil }
        let folderFile = folders[index]
        return folderFile
    }

    func useFile(at folder: Int, file: Int) {
        let audio = self.file(at: file, folderIndex: folder)
        coordinatorDelegate?.playlistViewModelDidSelectFile(self, file: audio!)
    }

    func removeDownloads() {
    }

    func getFiles(completion: @escaping ErrorCH) {
        files = []
        model?.allFiles { (files, currentPlayingFile, error) in
            defer {
            }
            self.files = files
            if let error = error {
                self.error = error
            }
            DispatchQueue.main.async {
                completion(error)
            }


            if let currentPlayingFile = currentPlayingFile {
                let indexPathOfCurrentPlaying = self.indexPath(of: currentPlayingFile)
                if !files.isEmpty {
                    self.viewDelegate?.scrollToCurrentlyPlayingFile(at: indexPathOfCurrentPlaying)
                }
            }

        }
    }

    func indexPath(of file: YSDriveFileProtocol) -> IndexPath {
        let fileFolderIndex = folders.index(where: { $0.id == file.folder.folderID })
        let filesInFolder = files.filter { $0.folder.folderID == file.folder.folderID && $0.isAudio }
        let fileIndex = filesInFolder.index(where: { $0.id == file.id })
        let indexPath = IndexPath.init(row: fileIndex ?? 0, section: fileFolderIndex ?? 0)
        return indexPath
    }
}

extension YSPlaylistViewModel: YSUpdatingDelegate {
    func downloadDidChange(_ download: YSDownloadProtocol, _ error: YSErrorProtocol?) {
        getFiles { (_) in
            self.viewDelegate?.filesDidChange(viewModel: self)
        }
    }

    func filesDidChange() {
        getFiles { (_) in
            self.viewDelegate?.filesDidChange(viewModel: self)
        }
    }
}

extension YSPlaylistViewModel: YSPlayerDelegate {
    func fileDidChange(file: YSDriveFileProtocol) {
        let indexOfUpdatingFile = files.index(where: { $0.id == file.id })
        if let indexOfUpdatingFile = indexOfUpdatingFile, files.indices.contains(indexOfUpdatingFile) {
            files[indexOfUpdatingFile] = file
        }
        viewDelegate?.fileDidChange(viewModel: self)
    }
}
