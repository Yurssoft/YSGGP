//
//  YSDriveFile.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/23/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation

class YSDriveFile : NSObject, YSDriveFileProtocol
{
    var fileName : String //Book 343
    var fileSize : String //108.03 MB (47 audio) or 10:18
    var mimeType : String
    var isAudio : Bool
    var fileDriveIdentifier : String
    var modifiedTime : String = ""
    var folder : YSFolder = YSFolder()
    
    var playedTime : String
    var isPlayed : Bool
    var isCurrentlyPlaying : Bool
    
    init(fileName : String?, fileSize : String?, mimeType : String?, fileDriveIdentifier : String?, folderName : String?, folderID : String?, playedTime : String?, isPlayed : Bool, isCurrentlyPlaying : Bool)
    {
        self.fileName = YSDriveFile.checkStringForNil(string: fileName)
        self.fileSize = YSDriveFile.checkStringForNil(string: fileSize)
        self.mimeType = YSDriveFile.checkStringForNil(string: mimeType)
        let mimeTypes = YSDriveFile.checkStringForNil(string: mimeType)
        if !mimeTypes.isEmpty && (mimeTypes.contains("mp3") || mimeTypes.contains("audio") || mimeTypes.contains("mpeg"))
        {
            self.isAudio = true
        }
        else
        {
            self.isAudio = false
        }
        self.fileDriveIdentifier = YSDriveFile.checkStringForNil(string: fileDriveIdentifier)
        self.folder.folderName = YSDriveFile.checkStringForNil(string: folderName)
        self.folder.folderID = YSDriveFile.checkStringForNil(string: folderID)
        
        self.playedTime = YSDriveFile.checkStringForNil(string: playedTime)
        self.isPlayed = isPlayed
        self.isCurrentlyPlaying = isCurrentlyPlaying
    }
    
    override init()
    {
        self.fileName = ""
        self.fileSize = ""
        self.isAudio = false
        self.mimeType = ""
        self.fileDriveIdentifier = ""
        self.playedTime = ""
        self.isPlayed = false
        self.isCurrentlyPlaying = false
    }
    
    class func checkStringForNil(string : String?) -> String
    {
        if string == nil
        {
            return ""
        }
        return string!
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
    
    func updateFileSize() -> UInt64
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
            print("Error: \(error)")
        }
        return fileSize
    }
    
    func removeLocalFile()
    {
        try? FileManager.default.removeItem(at: localFilePath()!)
        guard let indexToDelete = YSAppDelegate.appDelegate().filesOnDisk.index(of: fileDriveIdentifier) else { return }
        YSAppDelegate.appDelegate().filesOnDisk.remove(at: indexToDelete)
    }
    
    override var debugDescription: String
    {
        return "File name: \(fileName) ID: \(fileDriveIdentifier) FolderID: \(folder.folderID) Folder name: \(folder.folderName) IS AUDIO: \(isAudio)\t"
    }
}
