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

class YSPlayerViewModel: NSObject, YSPlayerViewModelProtocol, AVAudioPlayerDelegate
{
    let commandCenter = MPRemoteCommandCenter.shared()
    
    weak var playerDelegate: YSPlayerDelegate?
    //TODO:save time each 10 seconds
    var timer : Timer?
    
    var error: YSErrorProtocol = YSError.init()
    {
        didSet
        {
            if !error.isEmpty()
            {
                viewDelegate?.errorDidChange(viewModel: self, error: error)
            }
        }
    }
    
    deinit
    {
        player?.pause()
        timer?.invalidate()
    }
    
    weak var viewDelegate: YSPlayerViewModelViewDelegate?
    weak var coordinatorDelegate: YSPlayerViewModelCoordinatorDelegate?
    
    var files : [YSDriveFileProtocol] = []
    {
        didSet
        {
            if files.count > 0 || currentFile != nil
            {
                coordinatorDelegate?.showPlayer()
            }
            viewDelegate?.playerDidChange(viewModel: self)
        }
    }
    
    var model: YSPlaylistAndPlayerModelProtocol?
    {
        didSet
        {
            timer = Timer.every(1.seconds)
            { [weak self] in
                guard let sself = self else { return }
                sself.viewDelegate?.timeDidChange(viewModel: sself)
                sself.updateNowPlayingInfoElapsedTime()
            }
            //TODO:fix multiple times next
            commandCenter.playCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.play()
                return .success
            })
            
            commandCenter.pauseCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.pause()
                return .success
            })
            
            commandCenter.nextTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.next()
                return .success
            })
            
            commandCenter.previousTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
                guard let sself = self else { return .commandFailed }
                sself.previous()
                return .success
            })
            self.getFiles()
        }
    }
    
    func getFiles()
    {
        model?.allFiles()
            { (files, currentPlaying, error) in
                var playerFiles = [YSDriveFileProtocol]()
                let folders = self.selectFolders(from: files)
                for folder in folders
                {
                    let filesInFolder = files.filter{ $0.folder.folderID == folder.fileDriveIdentifier && $0.isAudio }
                    playerFiles.append(contentsOf: filesInFolder)
                }
                if  let localFileExists = currentPlaying?.localFileExists(), currentPlaying != nil && self.currentFile == nil && localFileExists
                {
                    self.currentFile = currentPlaying
                }
                if self.currentFile == nil && currentPlaying == nil
                {
                    let audioFiles = files.filter { $0.isAudio }
                    if let firstAudio = audioFiles.first
                    {
                        self.currentFile = firstAudio
                        self.update(file: self.currentFile, isCurrent: true)
                    }
                }
                self.files = playerFiles
                if let error = error
                {
                    self.error = error
                }
        }
    }
    
    func selectFolders(from files: [YSDriveFileProtocol]) -> [YSDriveFileProtocol]
    {
        let folders = files.filter()
            {
                let folderFile = $0
                if !folderFile.isAudio
                {
                    let filesInFolder = files.filter { $0.folder.folderID == folderFile.fileDriveIdentifier && $0.isAudio }
                    return filesInFolder.count > 0
                }
                else
                {
                    return false
                }
        }
        return folders
    }

    var player: AVAudioPlayer?
    
    var isPlaying : Bool
    {
        return player?.isPlaying ?? false
    }
    
    //TODO: synchronize volume with system and create variable for volume
    var playerVolume: Float
    {
        return player?.volume ?? 0.0
    }
    
    var currentFile: YSDriveFileProtocol?
    {
        didSet
        {
            if var currentFile = currentFile
            {
                guard let fileUrl = currentFile.localFilePath(), let audioPlayer = try? AVAudioPlayer(contentsOf: fileUrl) else { return }
                updateNowPlayingInfoForCurrentPlaybackItem()
                player?.stop()
                player?.delegate = nil
                audioPlayer.delegate = self
                audioPlayer.prepareToPlay()
                player = audioPlayer
                let fileTime = Double(currentFile.playedTime) ?? 0
                if fileTime > 1.0.seconds
                {
                    seek(to: fileTime)
                }
            }
            playerDelegate?.currentFilePlayingDidChange(viewModel: self)
        }
    }
    
    var nextFile: YSDriveFileProtocol?
    {
        guard let currentPlaybackFile = currentFile, files.count > 0 else { return files.first }
        
        let nextItemIndex = files.index(where: {$0.fileDriveIdentifier == currentPlaybackFile.fileDriveIdentifier})! + 1
        if nextItemIndex >= files.count { return files.first }
        
        return files[nextItemIndex]
    }
    
    var previousFile: YSDriveFileProtocol?
    {
        guard let currentPlaybackFile = currentFile, files.count > 0 else { return files.last }
        
        let previousItemIndex = files.index(where: {$0.fileDriveIdentifier == currentPlaybackFile.fileDriveIdentifier})! - 1
        if previousItemIndex < 0 { return files.last }
        
        return files[previousItemIndex]
    }
    
    var nowPlayingInfo: [String : AnyObject]?
    
    var fileDuration: TimeInterval
    {
        return player?.duration ?? 0
    }
    
    var fileCurrentTime: TimeInterval
    {
        return player?.currentTime ?? 0
    }
    
    func togglePlayPause()
    {
        isPlaying ? self.pause() : self.play()
    }
    
    func play(file: YSDriveFileProtocol?)
    {
        if file == nil && currentFile == nil
        {
            currentFile = files.first
        }
        else
        {
            currentFile = file
        }
        coordinatorDelegate?.showPlayer()
        
        play()
    }
    
    func play()
    {
        guard let player = player else
        {
            play(file: currentFile)
            return
        }
        update(file: currentFile, isCurrent: true)
        player.play()
        viewDelegate?.playerDidChange(viewModel: self)
        updateNowPlayingInfoForCurrentPlaybackItem()
    }
    
    func pause()
    {
        update(file: currentFile, isCurrent: true)
        player?.pause()
        viewDelegate?.playerDidChange(viewModel: self)
        updateNowPlayingInfoForCurrentPlaybackItem()
    }
    
    func next()
    {
        update(file: currentFile, isCurrent: false)
        play(file: nextFile)
        viewDelegate?.playerDidChange(viewModel: self)
        updateNowPlayingInfoForCurrentPlaybackItem()
    }
    
    func previous()
    {
        update(file: currentFile, isCurrent: false)
        play(file: previousFile)
        viewDelegate?.playerDidChange(viewModel: self)
        updateNowPlayingInfoForCurrentPlaybackItem()
    }
    
    func set(volume: Float)
    {
        player?.volume = volume
    }
    
    //MARK: - Now Playing Info
    
    func updateNowPlayingInfoForCurrentPlaybackItem()
    {
        guard let player = player, let currentPlaybackItem = currentFile else
        {
            let emptyPlayingInfo = [:] as [String : AnyObject]
            set(emptyPlayingInfo)
            return
        }
        
        var nowPlayingInfo = [MPMediaItemPropertyTitle: currentPlaybackItem.fileName,
                              MPMediaItemPropertyAlbumTitle: currentPlaybackItem.folder.folderName,
                              MPMediaItemPropertyPlaybackDuration: player.duration,
                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float),
                              MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: player.currentTime as Double) ] as [String : Any]
        
        if let image = UIImage(named: "song")
        {
            let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
                return image
            })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        set(nowPlayingInfo as [String : AnyObject]?)
    }
    
    func updateNowPlayingInfoElapsedTime()
    {
        guard let player = player, var nowPlayingInfo = nowPlayingInfo else { return }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: player.currentTime as Double)
        
        set(nowPlayingInfo)
    }
    
    func set(_ nowPlayingInfo: [String: AnyObject]?)
    {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
    }
    
    //MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        nextFile == nil ? updateNowPlayingInfoForCurrentPlaybackItem() : next()
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer)
    {
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int)
    {
        if AVAudioSessionInterruptionOptions(rawValue: UInt(flags)) == .shouldResume
        {
            play()
        }
    }
    
    func seek(to time:Double)
    {
        update(file: currentFile, isCurrent: true)
        player?.currentTime = Double(time)
        viewDelegate?.timeDidChange(viewModel: self)
    }
    
    func seekFloat(to time:Float)
    {
        seek(to: Double(time))
    }
    
    private func update(file: YSDriveFileProtocol?, isCurrent:Bool)
    {
        if var currentFile = currentFile
        {
            currentFile.isCurrentlyPlaying = isCurrent
            currentFile.playedTime = String(describing: player?.currentTime)
            YSDatabaseManager.update(file: currentFile)
        }
    }
}

extension YSPlayerViewModel : YSDriveFileDownloaderDelegate
{
    func downloadDidChanged(_ download : YSDownloadProtocol,_ error: YSErrorProtocol?)
    {
        getFiles()
    }
}
