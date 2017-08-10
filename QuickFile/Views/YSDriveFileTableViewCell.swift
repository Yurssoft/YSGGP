//
//  YSDriveFileTableViewCell.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/23/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit
import DownloadButton

protocol YSDriveFileTableViewCellDelegate : class
{
    func downloadButtonPressed(_ file: YSDriveFileProtocol)
    func stopDownloadButtonPressed(_ file: YSDriveFileProtocol)
}

class YSDriveFileTableViewCell: UITableViewCell
{
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileInfoLabel: UILabel!
    @IBOutlet weak var fileImageView: UIImageView!
    weak var delegate: YSDriveFileTableViewCellDelegate?
    var file: YSDriveFileProtocol?
    
    @IBOutlet weak var downloadButton: PKDownloadButton!
    @IBOutlet weak var titleRightMarginConstraint: NSLayoutConstraint!
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
        downloadButton.delegate = nil
    }
    
    func configureForDrive(_ file : YSDriveFileProtocol?,_ delegate : YSDriveFileTableViewCellDelegate?, _ download : YSDownloadProtocol?)
    {
        self.file = file
        self.delegate = delegate
        downloadButton.delegate = self
        guard let file = file else { return }
        fileNameLabel?.text = file.fileName
        fileInfoLabel?.text = fileSize
        fileImageView?.image = UIImage(named: file.isAudio ? "song" : "folder")
        if file.isAudio
        {
            if file.localFileExists()
            {
                downloadButton.isHidden = true
                titleRightMarginConstraint.constant = 0.0
                return
            }
            downloadButton.superview?.bringSubview(toFront: downloadButton)
            downloadButton.isHidden = false
            titleRightMarginConstraint.constant = downloadButton.frame.width + 8
            if let download = download
            {
                switch download.downloadStatus
                {
                case .downloading(let progress):
                    downloadButton.state = .downloading
                    downloadButton.stopDownloadButton.progress = CGFloat(progress)
                    break
                case .pending:
                    downloadButton.state = .pending
                    downloadButton.pendingView.startSpin()
                    break
                }
            }
            else
            {
                downloadButton.state = .startDownload
                downloadButton.startDownloadButton.cleanDefaultAppearance()
                downloadButton.startDownloadButton.setImage(UIImage.init(named: "cloud_download"), for: .normal)
            }
        }
        else
        {
            downloadButton.isHidden = true
            titleRightMarginConstraint.constant = 0.0
        }
    }
    
    func configureForPlaylist(_ file : YSDriveFileProtocol?)
    {
        self.file = file
        fileImageView?.image = UIImage(named:"song")
        downloadButton.isHidden = true
        guard let file = file else { return }
        accessoryType = file.isPlayed ? .checkmark : .none
        if file.fileDriveIdentifier == YSAppDelegate.appDelegate().playerCoordinator.viewModel.currentFile?.fileDriveIdentifier
        {
            if let fileNameLabelFont = fileNameLabel?.font, let fileInfoLabelFont = fileInfoLabel?.font
            {
                fileNameLabel?.font = UIFont.boldSystemFont(ofSize: fileNameLabelFont.pointSize)
                fileInfoLabel?.font = UIFont.boldSystemFont(ofSize: fileInfoLabelFont.pointSize)
            }
            fileNameLabel.textColor = YSConstants.kDefaultBlueColor
            fileInfoLabel.textColor = YSConstants.kDefaultBlueColor
        }
        else
        {
            if let fileNameLabelFont = fileNameLabel?.font, let fileInfoLabelFont = fileInfoLabel?.font
            {
                fileNameLabel?.font = UIFont.systemFont(ofSize: fileNameLabelFont.pointSize)
                fileInfoLabel?.font = UIFont.systemFont(ofSize: fileInfoLabelFont.pointSize)
            }
            fileNameLabel.textColor = UIColor.black
            fileInfoLabel.textColor = UIColor.black
        }
        titleRightMarginConstraint.constant = 0.0
        fileNameLabel?.text = file.fileName
        fileInfoLabel?.text = fileSize
    }
    
    var fileSize: String
    {
        guard let file = file else { return "" }
        if file.isAudio, file.fileSize.characters.count > 0, var sizeInt = Int(file.fileSize)
        {
            sizeInt = sizeInt / 1024 / 1024
            return sizeInt > 0 ? "\(sizeInt) MB" : file.mimeType
        }
        else
        {
            return  file.mimeType
        }
    }
    
}

extension YSDriveFileTableViewCell: PKDownloadButtonDelegate
{
    func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState)
    {
        switch (state)
        {
        case .startDownload:
            downloadButton.state = .pending
            downloadButton.pendingView.startSpin()
            delegate?.downloadButtonPressed(file!)
            break
        case .pending, .downloading:
            downloadButton.state = .startDownload
            delegate?.stopDownloadButtonPressed(file!)
            break
        case .downloaded:
            downloadButton.isHidden = true
            break
        }
    }
}
