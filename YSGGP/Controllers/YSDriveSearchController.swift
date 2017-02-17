//
//  YSDriveSearchController.swift
//  YSGGP
//
//  Created by Yurii Boiko on 2/16/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import UIKit

class YSDriveSearchController : UITableViewController
{
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        
        let bundle = Bundle(for: YSDriveFileTableViewCell.self)
        let nib = UINib(nibName: YSDriveFileTableViewCell.nameOfClass, bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: YSDriveFileTableViewCell.nameOfClass)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem)
    {
        navigationController?.dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: YSDriveFileTableViewCell.nameOfClass, for: indexPath) as! YSDriveFileTableViewCell
        cell.configureForDrive(nil, nil, nil)
        return cell
    }
}

extension YSDriveSearchController : UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController)
    {
        print("search")
    }
}
