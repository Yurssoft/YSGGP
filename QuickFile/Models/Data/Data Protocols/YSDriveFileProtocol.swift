//
//  YSDriveFileProtocol.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/22/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation

protocol YSDriveFileProtocol
{
    var fileName : String { get set } //Book 343
    var fileSize : String { get set } //108.03 MB (47 audio) or 10:18
    var mimeType : String { get set }
    var pageToken : String { get set }
    var isAudio : Bool { get } //If true it is audio if false it is folder
    var fileDriveIdentifier : String { get set }
    var modifiedTime : String { get set }
    var folder : YSFolder { get set }
    var isDeletedFromDrive : Bool { get set }
    
    var playedTime : String { get set }
    var isPlayed : Bool { get set }
    var isCurrentlyPlaying : Bool { get set }
    
    func fileUrl() -> String
    func localFilePath() -> URL?
    mutating func updateFileSize() -> UInt64
    
    func localFileExists() -> Bool
    func removeLocalFile()
}
