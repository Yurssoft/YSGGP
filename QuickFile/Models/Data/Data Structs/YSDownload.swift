//
//  YSDownload.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/26/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import Foundation

struct YSDownload: YSDownloadProtocol {
    var id: String

    var downloadTask: URLSessionDownloadTask?
    var resumeData: Data?

    var totalSize: String?

    internal var downloadStatus: YSDownloadStatus = .pending

    init(id: String) {
        self.id = id
    }
}
