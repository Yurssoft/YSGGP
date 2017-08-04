//
//  YSDatabaseManager.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/31/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import Firebase
import SwiftMessages
import SwiftyBeaver

//                                      //files              //error           //next page token
typealias AllFilesCompletionHandler = ([YSDriveFileProtocol],YSErrorProtocol?, String?) -> Swift.Void
typealias AllFilesAndCurrentPlayingCompletionHandler = ([YSDriveFileProtocol], YSDriveFileProtocol?,YSErrorProtocol?) -> Swift.Void

class YSDatabaseManager
{
    private static let completionBlockDelay = 0.3
    
    class func save(pageToken: String, remoteFilesDict: [String : Any],_ folder : YSFolder, _ completionHandler: @escaping AllFilesCompletionHandler)
    {
        if let ref = referenceForCurrentUser()
        {
            ref.child("files").runTransactionBlock({ (dbFilesData: MutableData) -> TransactionResult in
                var dbFilesArrayDict = databaseFilesDictionary(from: dbFilesData)
                let rootFolderID = YSFolder.rootFolder().folderID
                var ysFiles : [YSDriveFileProtocol] = []
                let nextPageToken = remoteFilesDict["nextPageToken"] as? String
                let remoteFilesArrayDict = remoteFilesDict["files"] as! [[String: Any]]
                
                var isRootFolderAdded = false

                var remoteFilesDict = [String : [String: Any]]()
                for var remoteFile in remoteFilesArrayDict
                {
                    //map ysfiledict to remote property names
                    let fileIdentifier = remoteFile["id"] as! String
                    var emptyFile = [String : Any]()
                    let mappedFile = mapFiles(dbFile: &emptyFile, remoteFile: remoteFile, folder: folder)
                    remoteFilesDict[fileIdentifier] = mappedFile
                }
                
                for var dbFile in dbFilesArrayDict
                {
                    if (dbFile.value["fileDriveIdentifier"] as! String) == YSFolder.rootFolder().folderID
                    {
                        continue
                    }
                    let currentFileIdentifier = dbFile.value["fileDriveIdentifier"] as! String
                    isRootFolderAdded = currentFileIdentifier == rootFolderID
                    if let remoteFile = remoteFilesDict[currentFileIdentifier]
                    {
                        dbFile.value = mergeFiles(dbFile: &dbFile.value, remoteFile: remoteFile, folder: folder)
                        remoteFilesDict[currentFileIdentifier] = nil
                    }
                    else
                    {
                        dbFile.value["isDeletedFromDrive"] = true
                    }
                    dbFile.value["pageToken"] = pageToken
                    var ysFile = dbFile.value.toYSFile()
                    checkIfFileExists(file: &ysFile)
                    ysFiles.append(ysFile)
                }
                
                for var remoteFile in remoteFilesDict
                {
                    remoteFile.value["pageToken"] = pageToken
                    dbFilesArrayDict[(remoteFile.value["fileDriveIdentifier"] as! String)] = remoteFile.value
                    var ysFile = remoteFile.value.toYSFile()
                    ysFile.pageToken = "1"
                    ysFiles.append(ysFile)
                }
                
                if !isRootFolderAdded && folder.folderID == rootFolderID
                {
                    let rootFolder = YSDriveFile.init(fileName: YSFolder.rootFolder().folderName, fileSize: "", mimeType: "application/vnd.google-apps.folder", fileDriveIdentifier: YSFolder.rootFolder().folderID, folderName: "", folderID: "", playedTime :"", isPlayed : false, isCurrentlyPlaying : false, isDeletedFromDrive : false, pageToken : "")
                    ysFiles.append(rootFolder)
                    let rootFolderDict = toDictionary(type: rootFolder)
                    dbFilesArrayDict[rootFolder.fileDriveIdentifier] = rootFolderDict
                }
                ref.child("files").setValue(dbFilesArrayDict)
                ysFiles = ysFiles.filter({ (ysFile) -> Bool in
                    return ysFile.folder.folderID == folder.folderID
                })
                ysFiles = sort(ysFiles: ysFiles)
                
                callCompletionHandler(nextPageToken: nextPageToken, completionHandler, files: ysFiles, YSError())
                return TransactionResult.abort()
            })
        }
        else
        {
            callCompletionHandler(nextPageToken: nil, completionHandler, files: [], notLoggedInError() as! YSError)
        }
    }
    
    class func checkIfFileExists(file: inout YSDriveFileProtocol)
    {
        if !YSAppDelegate.appDelegate().filesOnDisk.contains(file.fileDriveIdentifier) && file.localFileExists()
        {
            YSAppDelegate.appDelegate().filesOnDisk.append(file.fileDriveIdentifier)
            var file = file
            _ = file.updateFileSize()
        }
    }
    
    class func mapFiles(dbFile: inout [String: Any], remoteFile:[String: Any], folder : YSFolder) -> [String: Any]
    {
        var dbFile = dbFile
        dbFile["fileDriveIdentifier"] = remoteFile["id"]
        dbFile["folder"] = toDictionary(type: folder)
        dbFile["fileName"] = remoteFile["name"]
        dbFile["mimeType"] = remoteFile["mimeType"]
        dbFile["fileSize"] = remoteFile["size"]
        dbFile["isDeletedFromDrive"] = false
        return dbFile
    }
    
    class func mergeFiles(dbFile: inout [String: Any], remoteFile:[String: Any], folder : YSFolder) -> [String: Any]
    {
        var dbFile = dbFile
        dbFile["fileDriveIdentifier"] = remoteFile["fileDriveIdentifier"]
        dbFile["folder"] = toDictionary(type: folder)
        dbFile["fileName"] = remoteFile["fileName"]
        dbFile["mimeType"] = remoteFile["mimeType"]
        dbFile["fileSize"] = remoteFile["fileSize"]
        dbFile["isDeletedFromDrive"] = false
        return dbFile
    }
    
    //TODO: use page token to get files
    class func offlineFiles(pageToken: String, folder: YSFolder,_ error: YSError,_ completionHandler: @escaping AllFilesCompletionHandler)
    {
        if let ref = referenceForCurrentUser()
        {
            ref.child("files").runTransactionBlock({ (dbFiles: MutableData) -> TransactionResult in
                var sortedFiles : [YSDriveFileProtocol] = []
                if dbFiles.hasChildren()
                {
                    var files = [YSDriveFileProtocol]()
                    for currentDatabaseFile in dbFiles.children
                    {
                        let databaseFile = currentDatabaseFile as! MutableData
                        let dbFile = databaseFile.value as! [String : Any]
                        var ysFile = dbFile.toYSFile()
                        if ysFile.folder.folderID == folder.folderID
                        {
                            files.append(ysFile)
                        }
                    }
                    sortedFiles = sort(ysFiles: files)
                }
                callCompletionHandler(nextPageToken: nil, completionHandler, files: sortedFiles, error)
                return TransactionResult.abort()
            })
        }
        else
        {
            callCompletionHandler(nextPageToken: nil, completionHandler, files: [], error)
        }
    }
    
    class func deleteAllDownloads(_ completionHandler: @escaping ErrorCompletionHandler)
    {
        if let ref = referenceForCurrentUser()
        {
            ref.child("files").runTransactionBlock({ (dbFiles: MutableData) -> TransactionResult in
                if dbFiles.hasChildren()
                {
                    for currentDatabaseFile in dbFiles.children
                    {
                        let databaseFile = currentDatabaseFile as! MutableData
                        let dbFile = databaseFile.value as! [String : Any]
                        let ysFile = dbFile.toYSFile()
                        ysFile.removeLocalFile()
                        YSAppDelegate.appDelegate().fileDownloader?.cancelDownloading(file: ysFile)
                    }
                }
                let error = YSError(errorType: YSErrorType.none, messageType: Theme.success, title: "Deleted", message: "All local downloads deleted", buttonTitle: "GOT IT")
                completionHandler(error)
                return TransactionResult.abort()
            })
        }
        else
        {
            completionHandler(notLoggedInError())
        }
    }
    
    class func deletePlayedDownloads(_ completionHandler: @escaping ErrorCompletionHandler)
    {
        if let ref = referenceForCurrentUser()
        {
            ref.child("files").runTransactionBlock({ (dbFiles: MutableData) -> TransactionResult in
                if dbFiles.hasChildren()
                {
                    for currentDatabaseFile in dbFiles.children
                    {
                        let databaseFile = currentDatabaseFile as! MutableData
                        let dbFile = databaseFile.value as! [String : Any]
                        let ysFile = dbFile.toYSFile()
                        if (ysFile.isPlayed)
                        {
                            ysFile.removeLocalFile()
                            YSAppDelegate.appDelegate().fileDownloader?.cancelDownloading(file: ysFile)
                        }
                    }
                }
                let error = YSError(errorType: YSErrorType.none, messageType: Theme.success, title: "Deleted", message: "Played local downloads deleted", buttonTitle: "GOT IT")
                completionHandler(error)
                return TransactionResult.abort()
            })
        }
        else
        {
            completionHandler(notLoggedInError())
        }
    }
    
    class func deleteDatabase(_ completionHandler: @escaping ErrorCompletionHandler)
    {
        if let ref = referenceForCurrentUser()
        {
            ref.child("files").runTransactionBlock({ (dbFiles: MutableData) -> TransactionResult in
                ref.child("files").setValue([:])
                let error = YSError(errorType: YSErrorType.none, messageType: Theme.success, title: "Deleted", message: "Database deleted", buttonTitle: "GOT IT")
                completionHandler(error)
                return TransactionResult.abort()
            })
        }
        else
        {
            completionHandler(notLoggedInError())
        }
    }
    
    class func allFilesWithCurrentPlaying(completionHandler: @escaping AllFilesAndCurrentPlayingCompletionHandler)
    {
        if let ref = referenceForCurrentUser()
        {
            ref.child("files").runTransactionBlock({ (dbFiles: MutableData) -> TransactionResult in
                var sortedFiles : [YSDriveFileProtocol] = []
                var currentPlayingFile : YSDriveFileProtocol? = nil
                if dbFiles.hasChildren()
                {
                    var files = [YSDriveFileProtocol]()
                    for currentDatabaseFile in dbFiles.children
                    {
                        let databaseFile = currentDatabaseFile as! MutableData
                        let dbFile = databaseFile.value as! [String : Any]
                        let ysFile = dbFile.toYSFile()
                        if ysFile.isCurrentlyPlaying && ysFile.localFileExists()
                        {
                            currentPlayingFile = ysFile
                        }
                        files.append(ysFile)
                    }
                    sortedFiles = sort(ysFiles: files)
                }
                completionHandler(sortedFiles, currentPlayingFile, nil)
                return TransactionResult.abort()
            })
        }
        else
        {
            completionHandler([], nil, notLoggedInError())
        }
    }
    
    private class func notLoggedInError() -> YSErrorProtocol
    {
        let error = YSError(errorType: YSErrorType.notLoggedInToDrive, messageType: Theme.warning, title: "Not logged in", message: "Not logged in to drive", buttonTitle: "Login")
        return error
    }
    
    class func update(file: YSDriveFileProtocol)
    {
        if let ref = referenceForCurrentUser()
        {
            ref.child("files/\(file.fileDriveIdentifier)").runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                let updatedFile = toDictionary(type: file)
                ref.child("files/\(file.fileDriveIdentifier)").updateChildValues(updatedFile)
                return TransactionResult.abort()
            })
        }
    }
    
    private class func sort(ysFiles: [YSDriveFileProtocol]) -> [YSDriveFileProtocol]
    {
        let sortedFiles = ysFiles.sorted(by: { (_ file1,_ file2) -> Bool in
            return file1.isAudio == file2.isAudio ? file1.fileName < file2.fileName : !file1.isAudio
        })
        return sortedFiles
    }
    
    private class func databaseFilesDictionary(from databaseFiles: MutableData) -> [String : [String: Any]]
    {
        var databaseFilesDictionary = [String : [String: Any]]()
        for currentDatabaseFile in databaseFiles.children
        {
            let databaseFile = currentDatabaseFile as! MutableData
            let dbFile = databaseFile.value as! [String : Any]
            if let fileDriveIdentifier = dbFile["fileDriveIdentifier"] as? String
            {
                databaseFilesDictionary[fileDriveIdentifier] = dbFile
            }
            else
            {
                let log = SwiftyBeaver.self
                log.error("Something wrong with dbFile : \(dbFile)")
            }
        }
        return databaseFilesDictionary
    }
    
    private class func referenceForCurrentUser() -> DatabaseReference?
    {
        if (Auth.auth().currentUser) != nil, let uud = Auth.auth().currentUser?.uid
        {
            let ref = Database.database().reference(withPath: "users/\(uud)")
            return ref
        }
        return nil
    }
    
    private class func callCompletionHandler(nextPageToken: String?, _ completionHandler: AllFilesCompletionHandler?, files : [YSDriveFileProtocol], _ error: YSError)
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + completionBlockDelay)
        {
            completionHandler!(files, error, nextPageToken)
        }
    }
}
