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
import DZNEmptyDataSet
import SwiftyBeaver

class YSDriveViewController: UITableViewController
{
    weak var toolbarView: YSToolbarView!
    
    var selectedIndexes : [IndexPath] = []
    //TODO: make relative urls, pagination, logged as, download wifi only, do not delete files from remote even if they are deleted, disallow refreshes in edit, memory leaks, firebase functions?, why is error is not displayed deep in drive?
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
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        let log = SwiftyBeaver.self
        log.info("")
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        let log = SwiftyBeaver.self
        log.info("")
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        let log = SwiftyBeaver.self
        log.info("")
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
        let footer = MJRefreshAutoNormalFooter.init
        { [weak self] () -> Void in
            guard let viewModel = self?.viewModel else { return }
            viewModel.getNextPartOfFiles
            {
                DispatchQueue.main.async
                {
                    self?.tableView.mj_footer.endRefreshing()
                }
            }
        }
        footer?.isAutomaticallyHidden = true
        tableView.mj_footer = footer
        
        tableView.mj_header = MJRefreshNormalHeader.init(refreshingBlock:
        { [weak self] () -> Void in
            guard let viewModel = self?.viewModel else { return }
            viewModel.refreshFiles
            {
                DispatchQueue.main.async
                {
                    self?.tableView.mj_header.endRefreshing()
                }
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        guard let viewModel = viewModel, !viewModel.isLoggedIn else { return }
        let errorMessage = YSError(errorType: YSErrorType.notLoggedInToDrive, messageType: Theme.warning, title: "Warning", message: "Could not get list, please login", buttonTitle: "Login", debugInfo: "")
        errorDidChange(viewModel: viewModel, error: errorMessage)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        SwiftMessages.hide()
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
            tableView.reloadData()
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
        if isEditing
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
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
    {
        if let file = viewModel?.file(at: indexPath.row), file.isAudio
        {
            return .insert
        }
        return .none
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
    
    func allPagesDownloaded(viewModel: YSDriveViewModelProtocol)
    {
        DispatchQueue.main.async
        { [weak self] in
            guard let viewModel = self?.viewModel else { return }
            if viewModel.allPagesDownloaded
            {
                self?.tableView.mj_footer.endRefreshingWithNoMoreData()
            }
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
        messageConfig.duration = YSConstants.kMessageDuration
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
        if error.errorType == .couldNotGetFileList && error.systemCode == -1009 //no internet code
        {
            let statusBarMessage = MessageView.viewFromNib(layout: .StatusLine)
            statusBarMessage.backgroundView.backgroundColor = UIColor.orange
            statusBarMessage.bodyLabel?.textColor = UIColor.white
            statusBarMessage.configureContent(body: error.message)
            var messageConfig = SwiftMessages.defaultConfig
            messageConfig.presentationContext = .window(windowLevel: UIWindowLevelNormal)
            messageConfig.preferredStatusBarStyle = .lightContent
            messageConfig.duration = .forever
            SwiftMessages.show(config: messageConfig, view: statusBarMessage)
            return
        }
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
                self.viewModel?.loginToDrive()
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
                SwiftMessages.hide()
                viewModel.refreshFiles {}
            }
            break
        default: break
        }
        var messageConfig = SwiftMessages.Config()
        messageConfig.duration = YSConstants.kMessageDuration
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
                selectedIndexes.append(indexPath)
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
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

extension YSDriveViewController : DZNEmptyDataSetSource
{
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString!
    {
        var promptText = "Browse your audio files from Google Drive"
        if let viewModel = viewModel, viewModel.isLoggedIn
        {
            promptText = "Folder is empty or there are no .mp3 files"
        }
        let attributes = [NSForegroundColorAttributeName: YSConstants.kDefaultBlueColor, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0)]
        let attributedString = NSAttributedString.init(string: promptText, attributes: attributes)
        return attributedString
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString!
    {
        var promptText = "Login"
        if let viewModel = viewModel, viewModel.isLoggedIn
        {
            promptText = "Reload"
        }
        let attributes = [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0)]
        let attributedString = NSAttributedString.init(string: promptText, attributes: attributes)
        return attributedString
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage!
    {
        if let viewModel = viewModel, viewModel.isLoggedIn
        {
            return UIImage.init(named: "folder_small")
        }
        return UIImage.init(named: "drive")
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor!
    {
        return UIColor.white
    }
}

extension YSDriveViewController : DZNEmptyDataSetDelegate
{
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool
    {
        guard let viewModel = viewModel, !viewModel.isDownloadingMetadata else { return false }
        return !viewModel.isLoggedIn || viewModel.numberOfFiles < 1
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!)
    {
        guard let viewModel = viewModel else { return }
        viewModel.isLoggedIn ? self.viewModel?.refreshFiles {} : viewModel.loginToDrive()
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool
    {
        return true
    }
}
