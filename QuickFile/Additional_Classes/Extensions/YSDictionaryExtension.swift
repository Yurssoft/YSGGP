//
//  YSDictionaryExtension.swift
//  YSGGP
//
//  Created by Yurii Boiko on 11/18/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Reflection
import Foundation

extension Dictionary {
    func toYSFile() -> YSDriveFileProtocol {
        var ysFile = YSDriveFile()
        for key in keys {
            let val = self[key]
            if let propertyKey = key as? String {
                if propertyKey == "folder", let value = val as? [String: Any] {
                    var folder = YSFolder()
                    folder.folderID = value[forKey: "folderID", ""]
                    folder.folderName = value[forKey: "folderName", ""]
                    try? set(folder, key: propertyKey, for: &ysFile)
                } else if propertyKey == "isAudio" { continue } else {
                    try? set(val ?? "", key: propertyKey, for: &ysFile)
                }
            }
        }
        return ysFile
    }
}

extension Dictionary where Value == Any {
    subscript<T>(forKey key: Key, defaultV: @autoclosure () -> T) -> T {
        get {
            guard let value = self[key] as? T else {
                return defaultV()
            }
            return value
        }
    }
}