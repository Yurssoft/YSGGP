//
//  YSDriveSearchModelProtocol.swift
//  YSGGP
//
//  Created by Yurii Boiko on 2/17/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import Foundation

typealias DriveSearchCompletionHandler = ([YSDriveFileProtocol], YSErrorProtocol?) -> Swift.Void

protocol YSDriveSearchModelProtocol
{
    func getFiles(for searchTerm: String, _ completionHandler: @escaping DriveSearchCompletionHandler)
}
