//
//  SwiftMessagesExtension.swift
//  QuickFile
//
//  Created by Yurii Boiko on 9/9/17.
//  Copyright © 2017 Yurii Boiko. All rights reserved.
//

import Foundation
import SwiftMessages

extension SwiftMessages {
    class func showNoInternetError(_ error: YSErrorProtocol) {
        let statusBarMessage = MessageView.viewFromNib(layout: .statusLine)
        statusBarMessage.backgroundView.backgroundColor = UIColor.orange
        statusBarMessage.bodyLabel?.textColor = UIColor.white
        statusBarMessage.configureContent(body: error.message)
        statusBarMessage.tapHandler = { _ in
            SwiftMessages.hide(id: YSConstants.kOffineStatusBarMessageID)
        }
        var messageConfig = defaultConfig
        messageConfig.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        messageConfig.preferredStatusBarStyle = .lightContent
        messageConfig.duration = .forever
        statusBarMessage.id = YSConstants.kOffineStatusBarMessageID
        show(config: messageConfig, view: statusBarMessage)
    }

    class func createMessage<T: MessageView>(_ error: YSErrorProtocol) -> T {
        let message = MessageView.viewFromNib(layout: .cardView)
        message.configureTheme(error.messageType)
        message.configureDropShadow()
        message.configureContent(title: error.title, body: error.message)
        if error.buttonTitle.count > 1 {
            message.button?.setTitle(error.buttonTitle, for: UIControlState.normal)
        } else {
            message.button?.removeFromSuperview()
        }
        guard let message1 = message as? T else {
            return T()
        }
        return message1
    }

    class func showDefaultMessage(_ message: MessageView, isMessageErrorMessage: Bool) {
        var messageConfig = SwiftMessages.Config()
        messageConfig.duration = isMessageErrorMessage ? .forever : YSConstants.kMessageDuration
        messageConfig.ignoreDuplicates = false
        messageConfig.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        SwiftMessages.hide(id: YSConstants.kOffineStatusBarMessageID)
        SwiftMessages.show(config: messageConfig, view: message)
    }
}
