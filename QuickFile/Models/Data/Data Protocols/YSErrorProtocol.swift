//
//  YSErrorProtocol.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/19/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation
import SwiftMessages

protocol YSErrorProtocol : Error
{
    var errorType : YSErrorType { get }
    var messageType : Theme { get }
    var title : String { get }
    var message : String { get }
    var buttonTitle : String { get }
    var debugInfo : String { get }
    var systemCode : Int { get }
    
    func isEmpty() -> Bool
    mutating func update(errorType : YSErrorType, messageType: Theme, title: String, message : String)
    mutating func update(errorType : YSErrorType, messageType: Theme, title: String, message : String, systemCode: Int)
}
