//
//  YSDriveTopViewController.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/4/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit
import FirebaseCrash

protocol YSDriveViewControllerDidFinishedLoading: class {
    func driveViewControllerDidLoaded(driveVC: YSDriveViewController, navigationController: UINavigationController)
}

class YSDriveTopViewController: UIViewController {
    @IBOutlet fileprivate weak var editButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var toolbarViewBottomConstraint: NSLayoutConstraint?
    @IBOutlet fileprivate weak var toolbarView: YSToolbarView?
    @IBOutlet weak var searchButton: UIBarButtonItem!
    weak var driveVC: YSDriveViewController?
    var shouldShowSearch = true
    var navigationTitleStr = ""

    weak var driveVCReadyDelegate: YSDriveViewControllerDidFinishedLoading?

    fileprivate let toolbarViewBottomConstraintVisibleConstant = 0 as CGFloat
    fileprivate let toolbarViewBottomConstraintHiddenConstant = -100 as CGFloat

    override func viewDidLoad() {
        super.viewDidLoad()
        toolbarView?.ysToolbarDelegate = driveVC
        driveVC?.containingViewControllerViewDidLoad()
        driveVCReadyDelegate?.driveViewControllerDidLoaded(driveVC: driveVC!, navigationController: navigationController!)

        driveVC?.selectedIndexes.removeAll()
        driveVC?.setEditing(false, animated: false)
        toolbarView?.isHidden = true
        if !shouldShowSearch {
            navigationItem.rightBarButtonItems = [editButton]
        }
        navigationItem.title = navigationTitleStr
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        if parent == nil {
            driveVC?.viewModel?.driveViewControllerDidFinish()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let driveVC = driveVC, driveVC.isEditing else { return }
        driveVC.selectedIndexes.removeAll()
        driveVC.setEditing(false, animated: true)
        toolbarView?.isHidden = !driveVC.isEditing
        editButton.title = driveVC.isEditing ? "Done" : "Edit"
        tabBarController?.setTabBarVisible(isVisible: !driveVC.isEditing, animated: true, completion: nil)
    }

    deinit {
        driveVC?.viewModel = nil
        driveVC = nil
    }

    @IBAction func searchButtonTapped(_ sender: UIBarButtonItem) {
        logDriveSubdomain(.Controller, .Info, "")
        driveVC?.viewModel?.driveViewControllerDidRequestedSearch()
    }

    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        logDriveSubdomain(.Controller, .Info, "")
        guard let driveVC = driveVC else { return }
        driveVC.selectedIndexes.removeAll()
        driveVC.setEditing(!driveVC.isEditing, animated: true)
        toolbarView?.isHidden = !driveVC.isEditing
        editButton.title = driveVC.isEditing ? "Done" : "Edit"
        tabBarController?.setTabBarVisible(isVisible: !driveVC.isEditing, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueIdentifier = YSConstants.kDriveEmbededSegue

        if segue.identifier == segueIdentifier {
            driveVC = segue.destination as? YSDriveViewController
        }
    }
}
