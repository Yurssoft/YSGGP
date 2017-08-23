//
//  YSClassExtension.swift
//  QuickFile
//
//  Created by Yurii Boiko on 8/23/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import Foundation

protocol CallSimpleCompletion
{
    func callCompletion(_ completion: @escaping () -> Swift.Void)
}

extension CallSimpleCompletion
{
    func callCompletion(_ completion: @escaping () -> Swift.Void)
    {
        DispatchQueue.main.async
        {
            completion()
        }
    }
}

extension YSDriveViewModel : CallSimpleCompletion {}
extension YSDriveSearchViewModel : CallSimpleCompletion {}
