//
//  YSSettingsTopViewController.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/18/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit

class YSSettingsTopViewController: UIViewController {
    var settingsVC: YSSettingsTableViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCoordinator()
    }

    func setupCoordinator() {
        YSAppDelegate.appDelegate().settingsCoordinator.start(settingsViewController: settingsVC!)
    }

    @IBAction func refreshSettings(_ sender: UIBarButtonItem) {
        logSettingsSubdomain(.Controller, .Info, "")
        settingsVC.tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueIdentifier = YSConstants.kSettingsEmbededSegue

        if segue.identifier == segueIdentifier {
            settingsVC = segue.destination as? YSSettingsTableViewController
        }
    }
}
