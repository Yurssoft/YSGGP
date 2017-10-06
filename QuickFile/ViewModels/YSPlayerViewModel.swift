//
//  YSPlayerViewModel.swift
//  YSGGP
//
//  Created by Yurii Boiko on 12/28/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer
import SwiftyTimer

class YSPlayerViewModel: NSObject, YSPlayerViewModelProtocol, AVAudioPlayerDelegate {
    let commandCenter = MPRemoteCommandCenter.shared()

    weak var playerDelegate: YSPlayerDelegate?

    var elapsedTimeTimer: Timer?
    var savingPlayedTimeTimer: Timer?

    var error: YSErrorProtocol = YSError() {
        didSet {
            if !error.isEmpty() {
                viewDelegate?.errorDidChange(viewModel: self, error: error)
            }
        }
    }

    deinit {
        player?.pause()
        elapsedTimeTimer?.invalidate()
    }

    weak var viewDelegate: YSPlayerViewModelViewDelegate?
    weak var coordinatorDelegate: YSPlayerViewModelCoordinatorDelegate?

    var files: [YSDriveFileProtocol] = [] {
        didSet {
            if files.count > 0 || currentFile != nil {
                coordinatorDelegate?.showPlayer()
            }
            viewDelegate?.playerDidChange(viewModel: self)
        }
    }

    var model: YSPlaylistAndPlayerModelProtocol? {
        willSet {
            elapsedTimeTimer?.invalidate()
            elapsedTimeTimer = nil
            savingPlayedTimeTimer?.invalidate()
            savingPlayedTimeTimer = nil
        }
        didSet {
            savingPlayedTimeTimer = Timer.every(10.seconds) { [weak self] in
                guard let sself = self else { return }
                sself.updateCurrentPlayingFile(isCurrent: true)
            }

            elapsedTimeTimer = Timer.every(1.seconds) { [weak self] in
                guard let sself = self else { return }
                sself.viewDelegate?.timeDidChange(viewModel: sself)
                sself.updateNowPlayingInfoElapsedTime()
            }

            commandCenter.playCommand.addTarget (handler: { [weak self] _ -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.play()
                return .success
            })

            commandCenter.pauseCommand.addTarget (handler: { [weak self] _ -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.pause()
                return .success
            })

            commandCenter.nextTrackCommand.addTarget (handler: { [weak self] _ -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.next()
                return .success
            })

            commandCenter.previousTrackCommand.addTarget (handler: { [weak self] _ -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.previous()
                return .success
            })
            getFiles()
        }
    }

    var player: AVAudioPlayer?

    var isPlaying: Bool {
        return player?.isPlaying ?? false
    }

    var currentFile: YSDriveFileProtocol?

    var nextFile: YSDriveFileProtocol? {
        guard let currentPlaybackFile = currentFile, files.count > 0 else { return files.first }
        guard var nextItemIndex = files.index(where: {$0.fileDriveIdentifier == currentPlaybackFile.fileDriveIdentifier})
        else {
           if currentPlayingIndex <= files.count {
                return files[currentPlayingIndex]
            }
            return files.first
        }
        nextItemIndex += 1
        if nextItemIndex >= files.count { return files.first }

        return files[nextItemIndex]
    }

    var previousFile: YSDriveFileProtocol? {
        guard let currentPlaybackFile = currentFile, files.count > 0 else { return files.last }
        guard var previousItemIndex = files.index(where: {$0.fileDriveIdentifier == currentPlaybackFile.fileDriveIdentifier})
        else {
            if currentPlayingIndex <= files.count {
                return files[currentPlayingIndex]
            }
            return files.last
        }
        previousItemIndex -= 1
        if previousItemIndex < 0 { return files.last }

        return files[previousItemIndex]
    }

    var nowPlayingInfo: [String: AnyObject]?

    var fileDuration: TimeInterval {
        return player?.duration ?? 0
    }

    var fileCurrentTime: TimeInterval {
        return player?.currentTime ?? 0
    }

    var currentPlayingIndex: Int = 0

    fileprivate func updateCurrentPlaying() {
        if var currentFile = currentFile {
            if let currentFileIndex = files.index(where: {$0.fileDriveIdentifier == currentFile.fileDriveIdentifier}) {
                currentPlayingIndex = currentFileIndex
            }
            let isCurrentlyPlaying = currentFile.isCurrentlyPlaying && player != nil
            guard !isCurrentlyPlaying, let fileUrl = currentFile.localFilePath(), let audioPlayer = try? AVAudioPlayer(contentsOf: fileUrl) else {
                playerDelegate?.currentFilePlayingDidChange(viewModel: self)
                return
            }
            updateNowPlayingInfoForCurrentPlaybackItem()
            player?.stop()
            player?.delegate = nil
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            let audioSession = AVAudioSession.sharedInstance()
            audioPlayer.volume = audioSession.outputVolume
            player = audioPlayer
            let fileTime = Double(currentFile.playedTime) ?? 0
            if fileTime > 1.0.seconds {
                seek(to: fileTime)
            }
        }
        playerDelegate?.currentFilePlayingDidChange(viewModel: self)
    }

    func getFiles() {
        model?.allFiles { (files, currentPlaying, error) in
                var playerFiles = [YSDriveFileProtocol]()
                let folders = self.selectFolders(from: files)
                for folder in folders {
                    let filesInFolder = files.filter { $0.folder.folderID == folder.fileDriveIdentifier && $0.isAudio }
                    playerFiles += filesInFolder
                }
                if  let localFileExists = currentPlaying?.localFileExists(), currentPlaying != nil && self.currentFile == nil && localFileExists {
                    self.currentFile = currentPlaying
                }
                if self.currentFile == nil && currentPlaying == nil {
                    let audioFiles = files.filter { $0.isAudio }
                    if let firstAudio = audioFiles.first {
                        self.currentFile = firstAudio
                        self.updateCurrentPlayingFile(isCurrent: true)
                    }
                }
                if playerFiles.count == 0 && currentPlaying == nil {
                    self.currentFile = currentPlaying
                    self.coordinatorDelegate?.hidePlayer()
                }
                self.updateCurrentPlaying()
                self.files = playerFiles
                if let error = error {
                    self.error = error
                }
        }
    }

    func selectFolders(from files: [YSDriveFileProtocol]) -> [YSDriveFileProtocol] {
        let folders = files.filter {
                let folderFile = $0
                if !folderFile.isAudio {
                    let filesInFolder = files.filter { $0.folder.folderID == folderFile.fileDriveIdentifier && $0.isAudio }
                    return filesInFolder.count > 0
                } else {
                    return false
                }
        }
        return folders
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func play(file: YSDriveFileProtocol?) {
        if file == nil && currentFile == nil {
            currentFile = files.first
        } else {
            currentFile = file
        }
        updateCurrentPlaying()
        guard currentFile != nil else { return }
        coordinatorDelegate?.showPlayer()

        play()
    }

    func play() {
        guard let player = player else {
            play(file: currentFile)
            return
        }
        player.currentTime = Double((currentFile?.playedTime ?? "0.0")) ?? 0.0
        updateCurrentPlayingFile(isCurrent: true)
        player.play()
        viewDelegate?.playerDidChange(viewModel: self)
        updateNowPlayingInfoForCurrentPlaybackItem()
    }

    func pause() {
        updateCurrentPlayingFile(isCurrent: true)
        player?.pause()
        viewDelegate?.playerDidChange(viewModel: self)
        updateNowPlayingInfoForCurrentPlaybackItem()
    }

    func next() {
        updateCurrentPlayingFile(isCurrent: true)
        play(file: nextFile)
        viewDelegate?.playerDidChange(viewModel: self)
        updateNowPlayingInfoForCurrentPlaybackItem()
    }

    func previous() {
        updateCurrentPlayingFile(isCurrent: true)
        play(file: previousFile)
        viewDelegate?.playerDidChange(viewModel: self)
        updateNowPlayingInfoForCurrentPlaybackItem()
    }

    // MARK: - Now Playing Info

    func updateNowPlayingInfoForCurrentPlaybackItem() {
        guard let player = player, let currentPlaybackItem = currentFile else {
            let emptyPlayingInfo = [:] as [String: AnyObject]
            set(emptyPlayingInfo)
            return
        }

        var nowPlayingInfo = [MPMediaItemPropertyTitle: currentPlaybackItem.fileName,
                              MPMediaItemPropertyAlbumTitle: currentPlaybackItem.folder.folderName,
                              MPMediaItemPropertyPlaybackDuration: player.duration,
                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float),
                              MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: player.currentTime as Double) ] as [String: Any]

        if let image = UIImage(named: "song") {
            if #available(iOS 10.0, *) {
                let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (_) -> UIImage in
                    return image
                })
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
        }

        set(nowPlayingInfo as [String: AnyObject]?)
    }

    func updateNowPlayingInfoElapsedTime() {
        guard let player = player, var nowPlayingInfo = nowPlayingInfo else { return }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: player.currentTime as Double)
        set(nowPlayingInfo)
    }

    func set(_ nowPlayingInfo: [String: AnyObject]?) {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        nextFile == nil ? updateNowPlayingInfoForCurrentPlaybackItem() : next()
    }

    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
    }

    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        if AVAudioSessionInterruptionOptions(rawValue: UInt(flags)) == .shouldResume {
            play()
        }
    }

    func seek(to time: Double) {
        player?.currentTime = Double(time)
        updateCurrentPlayingFile(isCurrent: true)
        viewDelegate?.timeDidChange(viewModel: self)
    }

    func seekFloat(to time: Float) {
        seek(to: Double(time))
    }

    private func updateCurrentPlayingFile(isCurrent: Bool) {
        guard var currentFile = currentFile else { return }
        currentFile.isCurrentlyPlaying = isCurrent
        if let player = player {
            currentFile.playedTime = String(describing: player.currentTime)

            let elapsedTime = player.currentTime as Double
            let duration = player.duration as Double
            let remainingTime = duration - elapsedTime
            let remainingTimeInt = Int(round(remainingTime))
            currentFile.isPlayed = remainingTimeInt < 5 && !currentFile.isPlayed
        }
        self.currentFile = currentFile
        YSDatabaseManager.updatePlayingInfo(file: currentFile)
    }
}

extension YSPlayerViewModel: YSUpdatingDelegate {
    func downloadDidChange(_ download: YSDownloadProtocol, _ error: YSErrorProtocol?) {
        getFiles()
    }

    func filesDidChange() {
        getFiles()
    }
}
