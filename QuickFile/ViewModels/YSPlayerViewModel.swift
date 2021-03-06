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

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive(_:)),
                                               name: NSNotification.Name.UIApplicationWillResignActive,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMediaServicesReset),
                                               name: NSNotification.Name.AVAudioSessionMediaServicesWereReset,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMediaServicesLost),
                                               name: NSNotification.Name.AVAudioSessionMediaServicesWereLost,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: .AVAudioSessionRouteChange,
                                               object: AVAudioSession.sharedInstance())
    }

    @objc func applicationWillResignActive(_ notification: NSNotification) {
        deactivateAudioSession()
    }

    deinit {
        player?.pause()
        elapsedTimeTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    weak var viewDelegate: YSPlayerViewModelViewDelegate?
    weak var coordinatorDelegate: YSPlayerViewModelCoordinatorDelegate?

    var files: [YSDriveFileProtocol] = []

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

            commandCenter.skipForwardCommand.addTarget (handler: { [weak self] _ -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.forward15Seconds()
                return .success
            })

            commandCenter.skipBackwardCommand.addTarget (handler: { [weak self] _ -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.backwards15Seconds()
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
        guard var nextItemIndex = files.index(where: {$0.id == currentPlaybackFile.id})
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
        guard var previousItemIndex = files.index(where: {$0.id == currentPlaybackFile.id})
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

    private var currentPlayingIndex: Int = 0

    fileprivate func updateCurrentPlaying() {
        if var currentFile = currentFile, let fileUrl = currentFile.localFilePath(), fileUrl != player?.url {
            if let currentFileIndex = files.index(where: {$0.id == currentFile.id}) {
                currentPlayingIndex = currentFileIndex
            }
            createPlayer(fileUrl: fileUrl)
        }
    }

    private func createPlayer(fileUrl: URL) {
        var audioPlayerNotInited: AVAudioPlayer?
        do {
            audioPlayerNotInited = try AVAudioPlayer(contentsOf: fileUrl)
        } catch let error as NSError {
            logPlayerSubdomain(.Model, .Error, "Error initializing AVAudioPlayer: " + error.localizedDescriptionAndUnderlyingKey)
        }
        guard let audioPlayer = audioPlayerNotInited else { return }
        player?.stop()
        player?.delegate = nil
        audioPlayer.delegate = self
        let audioSession = AVAudioSession.sharedInstance()
        audioPlayer.volume = audioSession.outputVolume
        player = audioPlayer
    }

    func getFiles() {
        model?.allFiles { (files, currentPlaying, error) in
                var playerFiles = [YSDriveFileProtocol]()
                let folders = self.selectFolders(from: files)
                for folder in folders {
                    let filesInFolder = files.filter { $0.folder.folderID == folder.id && $0.isAudio }
                    playerFiles += filesInFolder
                }
                self.files = playerFiles
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

            if self.files.count > 0 || self.currentFile != nil {
                    self.coordinatorDelegate?.showPlayer()
                }
                self.viewDelegate?.playerDidChange(viewModel: self)
                if let error = error {
                    self.error = error
                }
        }
    }

    private func selectFolders(from files: [YSDriveFileProtocol]) -> [YSDriveFileProtocol] {
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

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func play(file: YSDriveFileProtocol?) {
        updateCurrentPlayingFile(isCurrent: false)
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
        guard let player = player, let currentFileUnwrapped = currentFile else {
            play(file: currentFile)
            return
        }
        let fileTime = Double(currentFileUnwrapped.playedTime) ?? 0
        if fileTime > 1.0.seconds {
            seek(to: fileTime)
        } else {
            updateCurrentPlayingFile(isCurrent: true)
        }
        activateAudioSession()
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

    func forward15Seconds() {
        guard let player = player else {
            return
        }
        let currentTime = player.currentTime
        let allTime = player.duration
        let secondsToAdd = 15.seconds
        let resultingTime = currentTime + secondsToAdd
        if resultingTime > allTime {
            next()
            return
        }
        seek(to: resultingTime)
        if !isPlaying {
            play()
        }
    }

    func backwards15Seconds() {
        guard let player = player else {
            return
        }
        let currentTime = player.currentTime
        let secondsToAdd = 15.seconds
        var resultingTime = currentTime - secondsToAdd
        if resultingTime < 0 {
            resultingTime = 0.0
        }
        seek(to: resultingTime)
        if !isPlaying {
            play()
        }
    }

    private func next() {
        play(file: nextFile)
        viewDelegate?.playerDidChange(viewModel: self)
        updateNowPlayingInfoForCurrentPlaybackItem()
    }

    private func previous() {
        play(file: previousFile)
        viewDelegate?.playerDidChange(viewModel: self)
        updateNowPlayingInfoForCurrentPlaybackItem()
    }

    // MARK: - Now Playing Info

    private func updateNowPlayingInfoForCurrentPlaybackItem() {
        guard let player = player, let currentPlaybackItem = currentFile else {
            let emptyPlayingInfo = [:] as [String: AnyObject]
            set(emptyPlayingInfo)
            return
        }

        var nowPlayingInfo = [MPMediaItemPropertyTitle: currentPlaybackItem.name,
                              MPMediaItemPropertyAlbumTitle: currentPlaybackItem.folder.folderName,
                              MPMediaItemPropertyPlaybackDuration: player.duration,
                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float),
                              MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: player.currentTime as Double) ] as [String: Any]

        if #available(iOS 10.0, *) {
            let artwork = MPMediaItemArtwork.init(boundsSize: #imageLiteral(resourceName: "song").size, requestHandler: { (_) -> UIImage in
                return #imageLiteral(resourceName: "song")
            })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        set(nowPlayingInfo as [String: AnyObject]?)
    }

    private func updateNowPlayingInfoElapsedTime() {
        guard let player = player, var nowPlayingInfo = nowPlayingInfo else { return }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: player.currentTime as Double)
        set(nowPlayingInfo)
    }

    private func set(_ nowPlayingInfo: [String: AnyObject]?) {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        nextFile == nil ? updateNowPlayingInfoForCurrentPlaybackItem() : next()
    }

    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        pause()
    }

    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        if AVAudioSessionInterruptionOptions(rawValue: UInt(flags)) == .shouldResume {
            play()
        }
    }

    func seek(to time: Double) {
        player?.currentTime = time
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
            let elapsedTime = player.currentTime as Double
            let duration = player.duration as Double
            let remainingTime = duration - elapsedTime
            let remainingTimeInt = Int(round(remainingTime))
            if !currentFile.isPlayed, remainingTimeInt < 20 {
                currentFile.isPlayed = true
            }
            let elapsedTimeStr = String(describing: elapsedTime)
            currentFile.playedTime = elapsedTimeStr
        }
        self.currentFile = currentFile
        if files.indices.contains(currentPlayingIndex) {
            files[currentPlayingIndex] = currentFile
        }
        playerDelegate?.fileDidChange(file: currentFile)
        YSDatabaseManager.updatePlayingInfo(file: currentFile)
    }

    //MARK: - oberver methodts
    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            logPlayerSubdomain(.Routing, .Error, "Error activating audio session: " + error.localizedDescriptionAndUnderlyingKey)
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    private func deactivateAudioSession() {
        if isPlaying {
            updateCurrentPlayingFile(isCurrent: true)
            return
        }
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch let error as NSError {
            logPlayerSubdomain(.Routing, .Error, "Error deactivating audio session: " + error.localizedDescriptionAndUnderlyingKey)
        }
    }

    @objc private func handleMediaServicesReset() {
        if let currentFileUrl = currentFile?.localFilePath() {
            createPlayer(fileUrl: currentFileUrl)
        }
        pause()
    }

    @objc private func handleMediaServicesLost() {
        pause()
    }

    @objc private func handleRouteChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason(rawValue: reasonValue) else {
                return
        }
        switch reason {
        case .newDeviceAvailable:
            break
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
                    pause()
                }
            }
        default: ()
        }
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
