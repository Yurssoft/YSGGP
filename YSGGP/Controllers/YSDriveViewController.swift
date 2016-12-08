//
//  YSDriveViewController.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/20/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit
import SwiftMessages
import MJRefresh
import M13ProgressSuite

class YSDriveViewController: UITableViewController
{
    weak var toolbarView: YSToolbarView!
    
    var selectedIndexes : [IndexPath] = []
    
    var viewModel: YSDriveViewModelProtocol?
    {
        willSet
        {
            viewModel?.viewDelegate = nil
        }
        didSet
        {
            viewModel?.viewDelegate = self
            refreshDisplay()
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let bundle = Bundle(for: YSDriveFileTableViewCell.self)
        let nib = UINib(nibName: YSDriveFileTableViewCell.nameOfClass, bundle: bundle)
        
        tableView.register(nib, forCellReuseIdentifier: YSDriveFileTableViewCell.nameOfClass)
    }
    
    func containingViewControllerViewDidLoad()
    {
        refreshDisplay()
        tableView.allowsMultipleSelectionDuringEditing = true
        configurePullToRefresh()
        navigationController?.showProgress()
    }
    
    func configurePullToRefresh()
    {
        tableView.mj_header = MJRefreshNormalHeader.init(refreshingBlock:
        { [weak self] () -> Void in
            self?.getFiles()
        })
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        if !(viewModel?.isLoggedIn)!
        {
            let errorMessage = YSError(errorType: YSErrorType.notLoggedInToDrive, messageType: Theme.warning, title: "Warning", message: "Could not get list, please login", buttonTitle: "Login", debugInfo: "")
            errorDidChange(viewModel: viewModel!, error: errorMessage)
        }
    }
    
    func deleteToolbarButtonTapped(_ sender: UIBarButtonItem)
    {
        viewModel?.removeDownloads()
    }
    
    func loginButtonTapped(_ sender: UIBarButtonItem)
    {
        viewModel?.loginToDrive()
    }
    
    func refreshDisplay()
    {
        if (viewIfLoaded != nil)
        {
            self.tableView.reloadData()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let viewModel = viewModel
        {
            return viewModel.numberOfFiles
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return YSConstants.kCellHeight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: YSDriveFileTableViewCell.nameOfClass, for: indexPath) as! YSDriveFileTableViewCell
        let file = viewModel?.file(at: indexPath.row)
        let download = viewModel?.download(for: file!)
        cell.configureForDrive(file, self, download)
        if isEditing && selectedIndexes.contains(indexPath)
        {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if isEditing, let file = viewModel?.file(at: indexPath.row), file.isAudio
        {
            selectedIndexes.append(indexPath)
        }
        else
        {
            viewModel?.useFile(at: (indexPath as NSIndexPath).row)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        if isEditing
        {
            let indexOfIndex = selectedIndexes.index(where: {$0.row == indexPath.row})
            selectedIndexes.remove(at: indexOfIndex!)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        let file = viewModel?.file(at: indexPath.row)
        return (file?.isAudio)!
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
    {
        if let file = viewModel?.file(at: indexPath.row), file.isAudio
        {
            return .insert
        }
        return .none
    }
    
    func getFiles()
    {
        if !(viewModel?.isLoggedIn)!
        {
            tableView.mj_header.endRefreshing()
            return
        }
        viewModel?.getFiles(completion:
        { _ in
            self.tableView.mj_header.endRefreshing()
        })
    }
}

extension YSDriveViewController: YSDriveFileTableViewCellDelegate
{
    func downloadButtonPressed(_ file: YSDriveFileProtocol)
    {
        viewModel?.download(file)
    }
    
    func stopDownloadButtonPressed(_ file: YSDriveFileProtocol)
    {
        viewModel?.stopDownloading(file)
    }
}

extension YSDriveViewController: YSDriveViewModelViewDelegate
{
    func filesDidChange(viewModel: YSDriveViewModelProtocol)
    {
        DispatchQueue.main.async
        {
            [weak self] in self?.tableView.reloadData()
        }
    }
    
    func metadataDownloadStatusDidChange(viewModel: YSDriveViewModelProtocol)
    {
        DispatchQueue.main.async
        {
            [weak self] in self?.navigationController?.setIndeterminate(viewModel.isDownloadingMetadata)
        }
    }
    
    func downloadErrorDidChange(viewModel: YSDriveViewModelProtocol, error: YSErrorProtocol, file : YSDriveFileProtocol)
    {
        let message = MessageView.viewFromNib(layout: .CardView)
        message.configureTheme(error.messageType)
        message.configureDropShadow()
        message.configureContent(title: error.title, body: error.message)
        message.button?.setTitle(error.buttonTitle, for: UIControlState.normal)
        switch error.errorType
        {
        case .couldNotDownloadFile:
            message.buttonTapHandler =
                { _ in
                    self.downloadButtonPressed(file)
                    SwiftMessages.hide()
            }
            break
        default: break
        }
        var messageConfig = SwiftMessages.Config()
        messageConfig.duration = .forever
        messageConfig.ignoreDuplicates = false
        messageConfig.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        SwiftMessages.show(config: messageConfig, view: message)
    }
    
    func downloadErrorDidChange(viewModel: YSDriveViewModelProtocol, error: YSErrorProtocol, download : YSDownloadProtocol)
    {
        downloadErrorDidChange(viewModel: viewModel, error: error, file: download.file)
    }
    
    func errorDidChange(viewModel: YSDriveViewModelProtocol, error: YSErrorProtocol)
    {
        let message = MessageView.viewFromNib(layout: .CardView)
        message.configureTheme(error.messageType)
        message.configureDropShadow()
        message.configureContent(title: error.title, body: error.message)
        message.button?.setTitle(error.buttonTitle, for: UIControlState.normal)
        switch error.errorType
        {
        case .cancelledLoginToDrive, .couldNotLoginToDrive, .notLoggedInToDrive:
            message.buttonTapHandler =
            { _ in
                self.loginButtonTapped(UIBarButtonItem())
                SwiftMessages.hide()
            }
            break
            
        case .loggedInToToDrive:
            message.buttonTapHandler =
            { _ in
                SwiftMessages.hide()
            }
            break
            
        case .couldNotGetFileList:
            message.buttonTapHandler =
            { _ in
                self.getFiles()
                SwiftMessages.hide()
            }
            break
        default: break
        }
        var messageConfig = SwiftMessages.Config()
        messageConfig.duration = .forever
        messageConfig.ignoreDuplicates = false
        messageConfig.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        SwiftMessages.show(config: messageConfig, view: message)
    }
    
    func reloadFile(at index: Int, viewModel: YSDriveViewModelProtocol)
    {
        DispatchQueue.main.async
        {
            let indexPath = IndexPath.init(row: index, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    func reloadFileDownload(at index: Int, viewModel: YSDriveViewModelProtocol)
    {
        DispatchQueue.main.async
        {
            let indexPath = IndexPath.init(row: index, section: 0)
            if let cell = self.tableView.cellForRow(at: indexPath) as? YSDriveFileTableViewCell
            {
                let file = viewModel.file(at: indexPath.row)
                let download = viewModel.download(for: file!)
                cell.configureForDrive(file, self, download)
            }
        }
    }
}

extension YSDriveViewController : YSToolbarViewDelegate
{
    func selectAllButtonTapped(toolbar: YSToolbarView)
    {
        selectedIndexes.removeAll()
        for index in 0..<tableView.numberOfRows(inSection: 0)
        {
            let indexPath = IndexPath.init(row: index, section: 0)
            let file = viewModel?.file(at: indexPath.row)
            if (file?.isAudio)!
            {
                selectedIndexes.append(indexPath)
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
    }
    
    func downloadButtonTapped(toolbar: YSToolbarView)
    {
        viewModel?.downloadFilesFor(selectedIndexes)
    }
    
    func deleteButtonTapped(toolbar: YSToolbarView)
    {
        let alertController = UIAlertController(title: "Confirm", message: "Deleting \(selectedIndexes.count) local files", preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Confirm", style: .destructive)
        { (action) in
            self.viewModel?.deleteDownloadsFor(self.selectedIndexes)
        }
        alertController.addAction(destroyAction)
        
        present(alertController, animated: true)
    }
}





