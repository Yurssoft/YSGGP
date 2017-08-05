//
//  YSDriveFile.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/23/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import SwiftyBeaver

struct YSDriveFile : YSDriveFileProtocol
{
    var fileName : String //Book 343
    var fileSize : String //108.03 MB (47 audio) or 10:18
    var mimeType : String
    var pageToken : String
    var isAudio : Bool
    {
        if !mimeType.isEmpty && (mimeType.contains("mp3") || mimeType.contains("audio") || mimeType.contains("mpeg"))
        {
            return true
        }
        else
        {
            return false
        }
    }
    var fileDriveIdentifier : String
    var modifiedTime : String = ""
    var folder : YSFolder = YSFolder()
    var isDeletedFromDrive : Bool = false
    
    var playedTime : String
    var isPlayed : Bool
    var isCurrentlyPlaying : Bool
    
    init(fileName : String?, fileSize : String?, mimeType : String?, fileDriveIdentifier : String?, folderName : String?, folderID : String?, playedTime : String?, isPlayed : Bool, isCurrentlyPlaying : Bool, isDeletedFromDrive : Bool, pageToken : String?)
    {
        self.fileName = checkStringForNil(string: fileName)
        self.fileSize = checkStringForNil(string: fileSize)
        self.mimeType = checkStringForNil(string: mimeType)
        self.fileDriveIdentifier = checkStringForNil(string: fileDriveIdentifier)
        self.folder.folderName = checkStringForNil(string: folderName)
        self.folder.folderID = checkStringForNil(string: folderID)
        
        self.playedTime = checkStringForNil(string: playedTime)
        self.isPlayed = isPlayed
        self.isCurrentlyPlaying = isCurrentlyPlaying
        self.isDeletedFromDrive = false
        self.pageToken = checkStringForNil(string: pageToken)
    }
    
    init()
    {
        self.fileName = ""
        self.fileSize = ""
        self.mimeType = ""
        self.fileDriveIdentifier = ""
        self.playedTime = ""
        self.isPlayed = false
        self.isCurrentlyPlaying = false
        self.isDeletedFromDrive = false
        self.pageToken = ""
    }
    
    func fileUrl() -> String
    {
        return String(format: "%@files/%@?alt=media&key=%@", YSConstants.kDriveAPIEndpoint, fileDriveIdentifier, YSConstants.kDriveAPIKey)
    }
    
    func localFilePath() -> URL?
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        if let url = URL(string: fileUrl())
        {
            if url.lastPathComponent.isEmpty
            {
                return nil
            }
            var fullPath = documentsPath.appendingPathComponent(url.lastPathComponent)
            fullPath = "\(fullPath).mp3"
            return URL(fileURLWithPath:fullPath)
        }
        return nil
    }
    
    func localFileExists() -> Bool
    {
        return YSAppDelegate.appDelegate().filesOnDisk.contains(fileDriveIdentifier)
    }
    
    mutating func updateFileSize() -> UInt64
    {
        var fileSize : UInt64 = 0
        guard let filePath = localFilePath()?.path else { return fileSize }
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            fileSize = attr[FileAttributeKey.size] as! UInt64
            let dict = attr as NSDictionary
            fileSize = dict.fileSize()
            self.fileSize = String(fileSize)
        } catch {
            let log = SwiftyBeaver.self
            log.error("Error creating file path: \(error)")
        }
        return fileSize
    }
    
    func removeLocalFile()
    {
        try? FileManager.default.removeItem(at: localFilePath()!)
        guard let indexToDelete = YSAppDelegate.appDelegate().filesOnDisk.index(of: fileDriveIdentifier) else { return }
        YSAppDelegate.appDelegate().filesOnDisk.remove(at: indexToDelete)
    }
    
    var debugDescription: String
    {
        return "File name: \(fileName) ID: \(fileDriveIdentifier) FolderID: \(folder.folderID) Folder name: \(folder.folderName) IS AUDIO: \(isAudio)\t"
    }
}

fileprivate func checkStringForNil(string : String?) -> String
{
    if string == nil
    {
        return ""
    }
    return string!
}
