//
//  YSError.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/19/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import SwiftMessages
import SwiftyBeaver

struct YSError : YSErrorProtocol
{
    var errorType : YSErrorType
    var messageType: Theme
    var title: String
    var message : String
    let buttonTitle : String
    let debugInfo : String
    var systemCode : Int
    
    init(errorType : YSErrorType, messageType: Theme, title: String, message : String, buttonTitle : String)
    {
        self.init(errorType : errorType, messageType: messageType, title: title, message : message, buttonTitle : buttonTitle, systemCode : -1)
    }
    
    init(errorType : YSErrorType, messageType: Theme, title: String, message : String, buttonTitle : String, systemCode : Int)
    {
        self.errorType = errorType
        self.messageType = messageType
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.debugInfo = ""
        self.systemCode = systemCode
    }
    
    init(errorType : YSErrorType, messageType: Theme, title: String, message : String, buttonTitle : String, debugInfo : String)
    {
        self.init(errorType : errorType, messageType: messageType, title: title, message : message, buttonTitle : buttonTitle, debugInfo : debugInfo, systemCode : -1)
    }
    
    init(errorType : YSErrorType, messageType: Theme, title: String, message : String, buttonTitle : String, debugInfo : String, systemCode : Int)
    {
        self.errorType = errorType
        self.messageType = messageType
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.debugInfo = debugInfo
        self.systemCode = systemCode
        if !debugInfo.isEmpty
        {
            let log = SwiftyBeaver.self
            log.info("debug info : \(debugInfo)")
        }
    }
    
    init()
    {
        self.errorType = YSErrorType.none
        self.messageType = Theme.info
        self.title = ""
        self.message = ""
        self.buttonTitle = ""
        self.debugInfo = ""
        self.systemCode = -1
    }
    
    mutating func update(errorType : YSErrorType, messageType: Theme, title: String, message : String)
    {
        update(errorType: errorType, messageType: messageType, title: title, message: message, systemCode: -1)
    }
    
    mutating func update(errorType : YSErrorType, messageType: Theme, title: String, message : String, systemCode : Int)
    {
        self.errorType = errorType
        self.messageType = messageType
        self.title = title
        self.message = message
        self.systemCode = systemCode
    }
    
    func isEmpty() -> Bool
    {
        if
        self.errorType == YSErrorType.none &&
        self.messageType == Theme.info &&
        self.title == "" &&
        self.message == "" &&
        self.buttonTitle == "" &&
        self.debugInfo == ""
        {
            return true
        }
        return false
    }
}
