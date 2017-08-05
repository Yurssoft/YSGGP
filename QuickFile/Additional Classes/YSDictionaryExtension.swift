//
//  YSDictionaryExtension.swift
//  YSGGP
//
//  Created by Yurii Boiko on 11/18/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation

public extension Dictionary
{
    internal func toYSFile() -> YSDriveFileProtocol
    {
        var ysFile = YSDriveFile()
        for key in keys
        {
            let val = self[key]
            let propertyKey = key as! String
            if propertyKey == "folder"
            {
                let folder = YSFolder()
                let value = val as! [String : String]
                folder.folderID = value["folderID"]!
                folder.folderName = value["folderName"]!
                try! set(folder, key: propertyKey, for: &ysFile)
            }
            else if propertyKey == "isAudio" { continue }
            else
            {
                try! set(val ?? "", key: propertyKey, for: &ysFile)
            }
        }
        return ysFile
    }
}
