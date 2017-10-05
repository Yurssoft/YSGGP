//
//  YSDriveSearchController.swift
//  YSGGP
//
//  Created by Yurii Boiko on 2/16/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import UIKit
import SwiftMessages

class YSDriveSearchController : UITableViewController
{
    var viewModel: YSDriveSearchViewModelProtocol?
    {
        willSet
        {
            viewModel?.viewDelegate = nil
        }
        didSet
        {
            viewModel?.viewDelegate = self
        }
    }
    
    let searchController = UISearchController(searchResultsController: nil)
    fileprivate var pendingRequestForSearchModel: DispatchWorkItem?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.scopeButtonTitles = [YSSearchSectionType.all.rawValue, YSSearchSectionType.files.rawValue, YSSearchSectionType.folders.rawValue]
        searchController.searchBar.delegate = self
        tableView.tableHeaderView = searchController.searchBar
        
        let bundle = Bundle(for: YSDriveFileTableViewCell.self)
        let nib = UINib(nibName: YSDriveFileTableViewCell.nameOfClass, bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: YSDriveFileTableViewCell.nameOfClass)
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        
        let footer = MJRefreshAutoNormalFooter.init
        { [weak self] () -> Void in
            LogSearchSubdomain(.Controller, .Info, "Footer requested")
            guard let viewModel = self?.viewModel as? YSDriveSearchViewModel else
            {
                LogSearchSubdomain(.Controller, .Info, "Footer cancelled, no model")
                self?.tableView.mj_footer.endRefreshing()
                return
            }
            viewModel.getNextPartOfFiles
            { [weak viewModel] in
                LogSearchSubdomain(.Controller, .Info, "Footer finished with data")
                guard let viewModel = viewModel, viewModel.allPagesDownloaded else
                {
                    self?.tableView.mj_footer.endRefreshing()
                    return
                }
                self?.tableView.mj_footer.endRefreshingWithNoMoreData()
            }
        }
        footer?.isAutomaticallyHidden = true
        tableView.mj_footer = footer
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        viewModel?.subscribeToDownloadingProgress()
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem)
    {
        navigationController?.dismiss(animated: true)
        LogSearchSubdomain(.Controller, .Info, "")
        viewModel?.searchViewControllerDidFinish()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let viewModel = viewModel else { return 0 }
        switch YSSearchSection(rawValue: section)!
        {
        case .localFiles:
            return viewModel.numberOfLocalFiles
        case .globalFiles:
            return viewModel.numberOfGlobalFiles
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return YSConstants.kCellHeight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: YSDriveFileTableViewCell.nameOfClass, for: indexPath) as! YSDriveFileTableViewCell
        let file = viewModel?.file(at: indexPath)
        let download = viewModel?.download(for: file?.fileDriveIdentifier ?? "")
        cell.configureForDrive(file, self, download)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return section == YSSearchSection.localFiles.rawValue ? "Local results" : "Global results"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        LogSearchSubdomain(.Controller, .Info, "Row: \(indexPath.row)")
        searchController.isActive = false
        viewModel?.useFile(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension YSDriveSearchController : YSDriveFileTableViewCellDelegate
{
    func downloadButtonPressed(_ fileDriveIdentifier: String)
    {
        LogSearchSubdomain(.Controller, .Info, "File id: " + fileDriveIdentifier)
        viewModel?.download(fileDriveIdentifier)
    }
    
    func stopDownloadButtonPressed(_ fileDriveIdentifier: String)
    {
        LogSearchSubdomain(.Controller, .Info, "File id: " + fileDriveIdentifier)
        viewModel?.stopDownloading(fileDriveIdentifier)
    }
}

extension YSDriveSearchController : YSDriveSearchViewModelViewDelegate
{
    func filesDidChange(viewModel: YSDriveSearchViewModelProtocol)
    {
        LogSearchSubdomain(.Controller, .Info, "")
        DispatchQueue.main.async
        {
            self.tableView.reloadData()
        }
    }
    
    func metadataDownloadStatusDidChange(viewModel: YSDriveSearchViewModelProtocol)
    {
        LogSearchSubdomain(.Controller, .Info, "")
        DispatchQueue.main.async
        {
            if !viewModel.isDownloadingMetadata && !viewModel.allPagesDownloaded
            {
                self.tableView.mj_footer.endRefreshing()
            }
        }
    }
    
    func errorDidChange(viewModel: YSDriveSearchViewModelProtocol, error: YSErrorProtocol)
    {
        LogSearchSubdomain(.Controller, .Info, "")
        if error.isNoInternetError()
        {
            SwiftMessages.showNoInternetError(error)
            return
        }
        let message = SwiftMessages.createMessage(error)
        switch error.errorType
        {
        case .couldNotGetFileList:
            message.buttonTapHandler =
            { _ in
                SwiftMessages.hide()
            }
            break
        default:
            break
        }
        SwiftMessages.showDefaultMessage(message)
    }
    
    func downloadErrorDidChange(viewModel: YSDriveSearchViewModelProtocol, error: YSErrorProtocol, fileDriveIdentifier : String)
    {
        LogSearchSubdomain(.Controller, .Info, "File id: " + fileDriveIdentifier)
        let message = SwiftMessages.createMessage(error)
        switch error.errorType
        {
        case .couldNotDownloadFile:
            message.buttonTapHandler =
            { _ in
                self.downloadButtonPressed(fileDriveIdentifier)
                SwiftMessages.hide()
            }
            break
        default: break
        }
        SwiftMessages.showDefaultMessage(message)
    }
    
    func downloadErrorDidChange(viewModel: YSDriveSearchViewModelProtocol, error: YSErrorProtocol, download : YSDownloadProtocol)
    {
        downloadErrorDidChange(viewModel: viewModel, error: error, fileDriveIdentifier: download.fileDriveIdentifier)
    }
    
    func reloadFileDownload(at index: Int, viewModel: YSDriveSearchViewModelProtocol)
    {
        LogSearchSubdomain(.Controller, .Info, "Index: \(index)")
        DispatchQueue.main.async
        {
            let indexPath = IndexPath.init(row: index, section: 0)
            if let cell = self.tableView.cellForRow(at: indexPath) as? YSDriveFileTableViewCell
            {
                let file = viewModel.file(at: indexPath)
                let download = viewModel.download(for: file?.fileDriveIdentifier ?? "")
                cell.configureForDrive(file, self, download)
            }
        }
    }
}

extension YSDriveSearchController : UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController)
    {
        pendingRequestForSearchModel?.cancel()
        guard let viewModel1 = viewModel as? YSDriveSearchViewModel, let searchText = searchController.searchBar.text, searchText.characters.count > 1 else { return }
        viewModel1.searchTerm = searchText
        LogSearchSubdomain(.Controller, .Info, "Search text: " + searchText)
        viewModel1.updateLocalResults()
        // Wrap our request to viewModel in a work item
        let requestWorkItem = DispatchWorkItem { [weak viewModel1] in
            guard let viewModel2 = viewModel1 else { return }
            viewModel2.updateGlobalResults()
        }
        pendingRequestForSearchModel = requestWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(750), execute: requestWorkItem)
    }
}

extension YSDriveSearchController : UISearchBarDelegate
{
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int)
    {
        pendingRequestForSearchModel?.cancel()
        let section = YSSearchSectionType(rawValue: searchBar.scopeButtonTitles![selectedScope])
        guard let sectionType = section, let viewModel1 = viewModel as? YSDriveSearchViewModel else { return }
        LogSearchSubdomain(.Controller, .Info, "Section type: \(sectionType)")
        viewModel1.sectionType = sectionType
        viewModel1.updateLocalResults()
        // Wrap our request to viewModel in a work item
        let requestWorkItem = DispatchWorkItem { [weak viewModel1] in
            guard let viewModel2 = viewModel1 else { return }
            viewModel2.updateGlobalResults()
        }
        pendingRequestForSearchModel = requestWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(750), execute: requestWorkItem)
    }
}
