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
    var isFileOnDisk : Bool = false
    var folder : String = ""
    
    var fileUrl : String
    {
        return String(format: "%@files/%@?alt=media&key=%@", YSConstants.kDriveAPIEndpoint, fileDriveIdentifier, YSConstants.kDriveAPIKey)
    }
    
    init(fileName : String?, fileSize : String?, mimeType : String?, isAudio : Bool, fileDriveIdentifier : String?)
    {
        self.fileName = YSDriveFile.checkStringForNil(string: fileName)
        self.fileSize = YSDriveFile.checkStringForNil(string: fileSize)
        self.isAudio = isAudio
        self.mimeType = YSDriveFile.checkStringForNil(string: mimeType)
        self.fileDriveIdentifier = YSDriveFile.checkStringForNil(string: fileDriveIdentifier)
    }
    
    override init()
    {
        self.fileName = ""
        self.fileSize = ""
        self.isAudio = false
        self.mimeType = ""
        self.fileDriveIdentifier = ""
    }
    
    class func checkStringForNil(string : String?) -> String
    {
        if string == nil
        {
            return ""
        }
        return string!
    }
    
    func localFilePath() -> URL?
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        if let url = URL(string: fileUrl)
        {
            var fullPath = documentsPath.appendingPathComponent(url.lastPathComponent)
            fullPath = "\(fullPath).mp3"
            return URL(fileURLWithPath:fullPath)
        }
        return nil
    }
    
    func localFileExists() -> Bool
    {
        var isDir : ObjCBool = false
        if let path = localFilePath()?.path
        {
            let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
            self.isFileOnDisk = exists
            return exists
        }
        self.isFileOnDisk = false
        return false
    }
    
    func removeLocalFile()
    {
        try? FileManager.default.removeItem(at: localFilePath()!)
        self.isFileOnDisk = false
    }
}
