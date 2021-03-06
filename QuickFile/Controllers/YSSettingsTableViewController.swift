//
//  YSSettingsViewController.swift
//  YSGGP
//
//  Created by Yurii Boiko on 9/21/16.
//  Copyright © 2016 Yurii Boiko. All rights reserved.
//

import UIKit
import SwiftMessages
import GoogleSignIn
import Firebase

class YSSettingsTableViewController: UITableViewController {
    var viewModel: YSSettingsViewModel? {
        willSet {
            viewModel?.viewDelegate = nil
        }
        didSet {
            viewModel?.viewDelegate = self
            if isViewLoaded {
                downloadOnCellularSwitch.isOn = viewModel?.isCellularAccessAllowed ?? false
                tableView.reloadData()
            }
        }
    }
    @IBOutlet weak var downloadOnCellularSwitch: UISwitch!
    fileprivate var signInButton: GIDSignInButton?

    fileprivate let cellLogInOutIdentifier = "logInOutCell"
    fileprivate let cellLogInOutInfoIdentifier = "loggedInOutInfoCell"
    fileprivate let cellDeleteAllIdentifier = "deleteAllCell"
    fileprivate let cellDeletePlayedIdentifier = "deletePlayedDownloads"
    fileprivate let cellDeleteAllDatabaseMetadataIdentifier = "deleteAllMetadata"
    fileprivate let cellDownloadOnCellularIdentifier = "downloadOnCellular"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().scopes = YSConstants.kDriveScopes
        signInButton = GIDSignInButton.init()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return YSConstants.kCellHeight
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let identifier = cell.reuseIdentifier, let viewModel = viewModel else { return }
        switch identifier {
        case cellLogInOutInfoIdentifier:
            cell.textLabel?.text = viewModel.loggedString
        case cellLogInOutIdentifier:
            cell.textLabel?.textColor = viewModel.isLoggedIn ? UIColor.red : UIColor.black
            cell.textLabel?.text = viewModel.isLoggedIn ? "Log Out From Drive" : "Log In To Drive"
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logSettingsSubdomain(.Controller, .Info, "Index: \(indexPath.row)")
        if let cell = tableView.cellForRow(at: indexPath), let identifier = cell.reuseIdentifier, let viewModel = viewModel {
            switch identifier {
            case cellLogInOutIdentifier:
                if viewModel.isLoggedIn {
                    logOutFromDrive()
                } else {
                    loginToDrive()
                }
            case cellDeleteAllIdentifier:
                deleteAllDownloads()
            case cellDeletePlayedIdentifier:
                deletePlayedDownloads()
            case cellDeleteAllDatabaseMetadataIdentifier:
                deleteAllMetadata()
            default:
                break
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @IBAction func downloadOnCellularSwitchValueChanged(_ sender: UISwitch) {
        viewModel?.isCellularAccessAllowed = sender.isOn
    }
    func loginToDrive() {
        logSettingsSubdomain(.Controller, .Info, "")
        GIDSignIn.sharedInstance().signInSilently()
    }

    func deleteAllDownloads() {
        logSettingsSubdomain(.Controller, .Info, "")
        let alertController = UIAlertController(title: "Delete all downloads?", message: "This will delete all local copies. This operation cannot be undone.", preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        let destroyAction = UIAlertAction(title: "Delete", style: .destructive) { (_) in
            self.viewModel?.deleteAllFiles()
        }
        alertController.addAction(destroyAction)

        present(alertController, animated: true)
    }

    func deletePlayedDownloads() {
        logSettingsSubdomain(.Controller, .Info, "")
        let alertController = UIAlertController(title: "Delete all played downloads?", message: "This will delete already played local copies. This operation cannot be undone.", preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        let destroyAction = UIAlertAction(title: "Delete", style: .destructive) { (_) in
            self.viewModel?.deletePlayedFiles()
        }
        alertController.addAction(destroyAction)

        present(alertController, animated: true)
    }

    func deleteAllMetadata() {
        logSettingsSubdomain(.Controller, .Info, "")
        let alertController = UIAlertController(title: "Delete all metadata", message: "This will delete ALL database metadata and local file copies. This operation cannot be undone.", preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        let destroyAction = UIAlertAction(title: "Delete", style: .destructive) { (_) in
            self.viewModel?.deleteAllMetadata()
        }
        alertController.addAction(destroyAction)

        present(alertController, animated: true)
    }

    func logOutFromDrive() {
        logSettingsSubdomain(.Controller, .Info, "")
        let alertController = UIAlertController(title: "Log Out?", message: "If you log out you won't be able to download songs.", preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        let destroyAction = UIAlertAction(title: "Log Out", style: .destructive) { (_) in
            logSettingsSubdomain(.Controller, .Info, "")
            self.viewModel?.logOut()
        }
        alertController.addAction(destroyAction)

        present(alertController, animated: true)
    }
}

extension YSSettingsTableViewController: GIDSignInUIDelegate {
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        logSettingsSubdomain(.Controller, .Info, "")
        signIn.scopes = YSConstants.kDriveScopes
    }

    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        logSettingsSubdomain(.Controller, .Info, "")
        signIn.scopes = YSConstants.kDriveScopes
        present(viewController, animated: true, completion: nil)
    }

    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        logSettingsSubdomain(.Controller, .Info, "")
        signIn.scopes = YSConstants.kDriveScopes
        dismiss(animated: true)
    }
}

extension YSSettingsTableViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            let errorString = error.localizedDescription

            //could not sign in silently, call explicit sign in
            logSettingsSubdomain(.Controller, .Error, "Error signing in \(error)")
            if errorString.contains("error -4") || errorString.contains("couldn’t be completed") || errorString.contains("-4") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.signInButton?.sendActions(for: UIControlEvents.touchUpInside)
                }
                return
            }
            if errorString.contains("Code=-5") || errorString.contains("canceled") || errorString.contains("-5") {
                let messageCancelled = YSError(errorType: YSErrorType.notLoggedInToDrive, messageType: Theme.warning, title: "Warning", message: "Cancelled login to Drive", buttonTitle: "Login", debugInfo: error.localizedDescription)
                errorDidChange(viewModel: viewModel!, error: messageCancelled)
                return
            }
            let messagecouldNotLogOut = YSError(errorType: YSErrorType.couldNotLogOutFromDrive, messageType: Theme.warning, title: "Warning", message: "Could not log out from drive", buttonTitle: "Try again", debugInfo: error.localizedDescription)
            let messageCouldNotLogin = YSError(errorType: YSErrorType.couldNotLoginToDrive, messageType: Theme.warning, title: "Warning", message: "Could not login to Drive", buttonTitle: "Try again", debugInfo: error.localizedDescription)
            errorDidChange(viewModel: viewModel!, error: signIn.hasAuthInKeychain() ? messagecouldNotLogOut : messageCouldNotLogin)
            return
        }
        let authentication = user.authentication
        YSCredentialManager.shared.setTokens(refreshToken: (authentication?.refreshToken)!,
                                            accessToken: (authentication?.accessToken)!,
                                            availableTo: (authentication?.accessTokenExpirationDate)!)

        let credential = GoogleAuthProvider.credential(withIDToken: (authentication?.idToken)!,
                                                          accessToken: (authentication?.accessToken)!)
        Auth.auth().signIn(with: credential) { [weak self] (user, error) in
            logSettingsSubdomain(.Controller, .Info, "User signed in \(user.debugDescription), error \(String(describing: error?.localizedDescription))")
            guard let sself = self else { return }
            let messageLoggedIn = YSError(errorType: YSErrorType.loggedInToToDrive, messageType: Theme.success, title: "Success", message: "Logged in to Drive", buttonTitle: "GOT IT", debugInfo: "")
            sself.errorDidChange(viewModel: sself.viewModel!, error: messageLoggedIn)
            sself.viewModel?.successfullyLoggedIn()
        }
    }
}

extension YSSettingsTableViewController: YSSettingsViewModelViewDelegate {
    func errorDidChange(viewModel: YSSettingsViewModel, error: YSErrorProtocol) {
        logSettingsSubdomain(.Controller, .Info, "Error: message: " + error.message + " debug message" + error.debugInfo)
        let message = SwiftMessages.createMessage(error)
        switch error.errorType {
        case .loggedInToToDrive:
            message.buttonTapHandler = { _ in
                SwiftMessages.hide(id: message.id)
            }
        case .cancelledLoginToDrive, .couldNotLoginToDrive, .notLoggedInToDrive:
            message.buttonTapHandler = { _ in
                SwiftMessages.hide(id: message.id)
                self.loginToDrive()
            }

        case .couldNotLogOutFromDrive:
            message.buttonTapHandler = { _ in
                SwiftMessages.hide(id: message.id)
                self.logOutFromDrive()
            }

        default:
            message.buttonTapHandler = { _ in
                SwiftMessages.hide(id: message.id)
            }
        }
        SwiftMessages.showDefaultMessage(message, isMessageErrorMessage: error.messageType == .error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.tableView.reloadData()
        }
    }
}
