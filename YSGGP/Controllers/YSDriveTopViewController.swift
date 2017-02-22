//
//  YSDriveTopViewController.swift
//  YSGGP
//
//  Created by Yurii Boiko on 10/4/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit

protocol YSDriveViewControllerDidFinishedLoading: class
{
    func driveViewControllerDidLoaded(driveVC: YSDriveViewController, navigationController: UINavigationController)
}

class YSDriveTopViewController: UIViewController
{
    @IBOutlet fileprivate weak var editButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var toolbarViewBottomConstraint : NSLayoutConstraint?
    @IBOutlet fileprivate weak var toolbarView: YSToolbarView?
    var driveVC : YSDriveViewController?
    
    weak var driveVCReadyDelegate : YSDriveViewControllerDidFinishedLoading?
    
    fileprivate let toolbarViewBottomConstraintVisibleConstant = 0 as CGFloat
    fileprivate let toolbarViewBottomConstraintHiddenConstant = -100 as CGFloat
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        driveVC?.toolbarView = toolbarView
        driveVC?.toolbarView.ysToolbarDelegate = driveVC
        driveVC?.containingViewControllerViewDidLoad()
        driveVCReadyDelegate?.driveViewControllerDidLoaded(driveVC: driveVC!, navigationController: navigationController!)
        
        driveVC?.selectedIndexes.removeAll()
        driveVC?.setEditing(false, animated: false)
        toolbarView?.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
    }
    
    override func willMove(toParentViewController parent: UIViewController?)
    {
        super.willMove(toParentViewController: parent)
        if parent == nil
        {
            driveVC?.viewModel?.driveViewControllerDidFinish()
        }
    }
    
    deinit
    {
        driveVC?.viewModel = nil
        driveVC = nil
    }
    @IBAction func searchButtonTapped(_ sender: UIBarButtonItem)
    {
        driveVC?.viewModel?.driveViewControllerDidRequestedSearch()
    }
    
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem)
    {
        driveVC?.selectedIndexes.removeAll()
        driveVC?.setEditing(!(driveVC?.isEditing)!, animated: true)
        toolbarView?.isHidden = !(driveVC?.isEditing)!
        sender.title = (driveVC?.isEditing)! ? "Done" : "Edit"
        tabBarController?.setTabBarVisible(isVisible: !(driveVC?.isEditing)!, animated: true, completion:nil)
    }
    
    func loginButtonTapped(_ sender: AnyObject)
    {
        driveVC?.loginButtonTapped(sender as! UIBarButtonItem)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let segueIdentifier = YSConstants.kDriveEmbededSegue
        
        if segue.identifier == segueIdentifier
        {
            driveVC = segue.destination as? YSDriveViewController
        }
    }
}
