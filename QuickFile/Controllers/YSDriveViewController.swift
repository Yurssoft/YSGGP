//
//  YSDriveViewController.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/20/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit
import SwiftMessages
import M13ProgressSuite
import DZNEmptyDataSet

class YSDriveViewController: UITableViewController {
    var selectedIndexes = Set<IndexPath>()
    var viewModel: YSDriveViewModelProtocol? {
        willSet {
            viewModel?.viewDelegate = nil
        }
        didSet {
            viewModel?.viewDelegate = self
            refreshDisplay()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let bundle = Bundle(for: YSDriveFileTableViewCell.self)
        let nib = UINib(nibName: YSDriveFileTableViewCell.nameOfClass, bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: YSDriveFileTableViewCell.nameOfClass)

        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setIndeterminate(viewModel?.isDownloadingMetadata ?? false)
    }

    func containingViewControllerViewDidLoad() {
        refreshDisplay()
        tableView.allowsMultipleSelectionDuringEditing = true
        configurePullToRefresh()
        navigationController?.showProgress()
    }

    func configurePullToRefresh() {
        let footer = MJRefreshAutoNormalFooter.init { [weak self] () -> Void in
            SwiftMessages.hide(id: YSConstants.kOffineStatusBarMessageID)
            logDriveSubdomain(.Controller, .Info, "Footer requested")
            guard let viewModel = self?.viewModel as? YSDriveViewModel, let isEditing = self?.isEditing, !isEditing else {
                logDriveSubdomain(.Controller, .Info, "Footer cancelled, no model or editing")
                self?.tableView.mj_footer.endRefreshing()
                return
            }
            viewModel.getNextPartOfFiles { [weak viewModel] in
                logDriveSubdomain(.Controller, .Info, "Footer finished with data")
                guard let viewModel = viewModel, viewModel.allPagesDownloaded else {
                    self?.tableView.mj_footer.endRefreshing()
                    return
                }
                self?.tableView.mj_footer.endRefreshingWithNoMoreData()
            }
        }
        footer?.isAutomaticallyHidden = true
        tableView.mj_footer = footer

        tableView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: { [weak self] () -> Void in
            SwiftMessages.hide(id: YSConstants.kOffineStatusBarMessageID)
            logDriveSubdomain(.Controller, .Info, "Header requested")
            guard let viewModel = self?.viewModel as? YSDriveViewModel, let isEditing = self?.isEditing, !isEditing else {
                logDriveSubdomain(.Controller, .Info, "Header cancelled, no model or editing")
                self?.tableView.mj_header.endRefreshing()
                return
            }
            viewModel.refreshFiles {
                logDriveSubdomain(.Controller, .Info, "Header finished with data")
                self?.tableView.mj_header.endRefreshing()
                //set state to idle to have opportunity to fetch more data after user scrolled to bottom
                self?.tableView.mj_footer.state = .idle
            }
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel = viewModel, !viewModel.isLoggedIn else { return }
        let errorMessage = YSError(errorType: YSErrorType.notLoggedInToDrive, messageType: Theme.warning, title: "Warning", message: "Could not get list, please login", buttonTitle: "Login", debugInfo: "")
        errorDidChange(viewModel: viewModel, error: errorMessage)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SwiftMessages.hide()
    }

    func deleteToolbarButtonTapped(_ sender: UIBarButtonItem) {
        logDriveSubdomain(.Controller, .Info, "")
        viewModel?.removeDownloads()
    }

    func refreshDisplay() {
        logDriveSubdomain(.Controller, .Info, "")
        if viewIfLoaded != nil {
            tableView.reloadData()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let viewModel = viewModel {
            return viewModel.numberOfFiles
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return YSConstants.kCellHeight
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: YSDriveFileTableViewCell.nameOfClass, for: indexPath)
        if let cell = cell as? YSDriveFileTableViewCell {
            let file = viewModel?.file(at: indexPath.row)
            let download = viewModel?.download(for: file?.id ?? "")
            cell.configureForDrive(file, self, download)
        }
        if isEditing && selectedIndexes.contains(indexPath) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return isFileAudio(at: indexPath) || !isEditing
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return (isFileAudio(at: indexPath) || !isEditing) ? indexPath : nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logDriveSubdomain(.Controller, .Info, "Index: \(indexPath.row)")
        if isEditing {
            if !isFileAudio(at: indexPath) {
                return
            }
            selectedIndexes.insert(indexPath)
        } else {
            viewModel?.useFile(at: (indexPath as NSIndexPath).row)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        logDriveSubdomain(.Controller, .Info, "Index: \(indexPath.row)")
        if isEditing {
            if !isFileAudio(at: indexPath) {
                return
            }
            selectedIndexes.remove(indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isFileAudio(at: indexPath)
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return isFileAudio(at: indexPath) ? .insert : .none
    }

    private func isFileAudio(at indexPath: IndexPath) -> Bool {
        return (viewModel?.file(at: indexPath.row)?.isAudio ?? false)
    }
}

extension YSDriveViewController: YSDriveFileTableViewCellDelegate {
    func downloadButtonPressed(_ id: String) {
        logDriveSubdomain(.Controller, .Info, "File id: " + id)
        viewModel?.download(id)
    }

    func stopDownloadButtonPressed(_ id: String) {
        logDriveSubdomain(.Controller, .Info, "File id: " + id)
        viewModel?.stopDownloading(id)
    }
}

extension YSDriveViewController: YSDriveViewModelViewDelegate {
    func filesDidChange(viewModel: YSDriveViewModelProtocol) {
        logDriveSubdomain(.Controller, .Info, "")
        DispatchQueue.main.async {
            [weak self] in self?.tableView.reloadData()
        }
    }

    func metadataDownloadStatusDidChange(viewModel: YSDriveViewModelProtocol) {
        logDriveSubdomain(.Controller, .Info, "")
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.setIndeterminate(viewModel.isDownloadingMetadata)
            if viewModel.allPagesDownloaded && !viewModel.isDownloadingMetadata {
                self?.tableView.mj_footer.endRefreshingWithNoMoreData()
            }
        }
    }

    func downloadErrorDidChange(viewModel: YSDriveViewModelProtocol, error: YSErrorProtocol, id: String) {
        logDriveSubdomain(.Controller, .Info, "File id: " + id + " Error: message: " + error.message + " debug message" + error.debugInfo)
        let message = SwiftMessages.createMessage(error)
        switch error.errorType {
        case .couldNotDownloadFile:
            message.buttonTapHandler = { _ in
                self.downloadButtonPressed(id)
                SwiftMessages.hide()
            }
        default: break
        }
        SwiftMessages.showDefaultMessage(message, isMessageErrorMessage: error.messageType == .error)
    }

    func downloadErrorDidChange(viewModel: YSDriveViewModelProtocol, error: YSErrorProtocol, download: YSDownloadProtocol) {
        downloadErrorDidChange(viewModel: viewModel, error: error, id: download.id)
    }

    func errorDidChange(viewModel: YSDriveViewModelProtocol, error: YSErrorProtocol) {
        logDriveSubdomain(.Controller, .Info, "File id: " + " Error: message: " + error.message + " debug message" + error.debugInfo)
        if error.isNoInternetError() {
            SwiftMessages.showNoInternetError(error)
            return
        }
        let message = SwiftMessages.createMessage(error)
        switch error.errorType {
        case .cancelledLoginToDrive, .couldNotLoginToDrive, .notLoggedInToDrive:
            message.buttonTapHandler = { _ in
                self.viewModel?.loginToDrive()
                SwiftMessages.hide()
            }

        case .loggedInToToDrive:
            message.buttonTapHandler = { _ in
                SwiftMessages.hide()
            }

        case .couldNotGetFileList:
            message.buttonTapHandler = { _ in
                SwiftMessages.hide()
                viewModel.refreshFiles {}
            }
        default: break
        }
        SwiftMessages.showDefaultMessage(message, isMessageErrorMessage: error.messageType == .error)
    }

    func reloadFile(at index: Int, viewModel: YSDriveViewModelProtocol) {
        logDriveSubdomain(.Controller, .Info, "Inex: \(index)")
        DispatchQueue.main.async {
            let indexPath = IndexPath.init(row: index, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    func reloadFileDownload(at index: Int, download: YSDownloadProtocol, viewModel: YSDriveViewModelProtocol) {
        logDriveSubdomain(.Controller, .Info, "Inex: \(index)")
        DispatchQueue.main.async {
            let indexPath = IndexPath.init(row: index, section: 0)
            switch download.downloadStatus {
            case .downloaded, .downloadError, .pending, .cancelled:
                self.tableView.reloadRows(at: [indexPath], with: .none)
            default:
                if let cell = self.tableView.cellForRow(at: indexPath) as? YSDriveFileTableViewCell  {
                    cell.updateDownloadButton(download: download)
                } else {
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
    }
}

extension YSDriveViewController: DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var promptText = "Browse your audio files from Google Drive"
        if let viewModel = viewModel, viewModel.isLoggedIn {
            promptText = "Folder is empty or there are no .mp3 files"
        }
        let attributes = [NSAttributedStringKey.foregroundColor: YSConstants.kDefaultBlueColor, NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 18.0)]
        let attributedString = NSAttributedString.init(string: promptText, attributes: attributes)
        return attributedString
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        var promptText = "Login"
        if let viewModel = viewModel, viewModel.isLoggedIn {
            promptText = "Reload"
        }
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 17.0)]
        let attributedString = NSAttributedString.init(string: promptText, attributes: attributes)
        return attributedString
    }

    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        if let viewModel = viewModel, viewModel.isLoggedIn {
            return UIImage(named: "folder_small")
        }
        return UIImage(named: "drive")
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return UIColor.white
    }
}

extension YSDriveViewController: DZNEmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        guard let viewModel = viewModel, !viewModel.isDownloadingMetadata else { return false }
        return !viewModel.isLoggedIn || viewModel.numberOfFiles < 1
    }

    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        guard let viewModel = viewModel else { return }
        viewModel.isLoggedIn ? viewModel.refreshFiles {} : viewModel.loginToDrive()
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}

extension YSDriveViewController: YSToolbarViewDelegate {
    func selectAllButtonTapped(toolbar: YSToolbarView) {
        selectedIndexes.removeAll()
        if let viewModel = viewModel {
            for index in 0..<viewModel.numberOfFiles {
                if let file = viewModel.file(at: index), file.isAudio {
                    let indexPath = IndexPath.init(row: index, section: 0)
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                    selectedIndexes.insert(indexPath)
                }
            }
        }
    }

    func downloadButtonTapped(toolbar: YSToolbarView) {
        viewModel?.downloadFilesFor(selectedIndexes)
    }

    func deleteButtonTapped(toolbar: YSToolbarView) {
        if selectedIndexes.count < 1 {
            let error = YSError.init(errorType: .none, messageType: .warning, title: "Select files", message: "Please, select at least one file", buttonTitle: "")
            if let viewModel = viewModel {
                errorDidChange(viewModel: viewModel, error: error)
            }
            return
        }
        let alertController = UIAlertController(title: "Confirm", message: "Deleting \(selectedIndexes.count) local files", preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(cancelAction)

        let destroyAction = UIAlertAction(title: "Confirm", style: .destructive) { (_) in
            self.viewModel?.deleteDownloadsFor(self.selectedIndexes)
        }
        alertController.addAction(destroyAction)
        YSAppDelegate.topViewController()?.present(alertController, animated: true)
    }
}
