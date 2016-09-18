//
//  PimpNotifications.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 29/03/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

open class PimpNotifications {
    open static let sharedInstance = PimpNotifications()
    
    let settings = PimpSettings.sharedInstance
    
    func initNotifications(_ application: UIApplication) {
        // https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/IPhoneOSClientImp.html#//apple_ref/doc/uid/TP40008194-CH103-SW1
        let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        // the playback notification is displayed as an alert to the user, so we must call this
        application.registerUserNotificationSettings(notificationSettings)
        // registers with APNs
        application.registerForRemoteNotifications()
    }
    
    func didRegister(_ deviceToken: Data) {
        let hexToken = deviceToken.hexString()
        let token = PushToken(token: hexToken)
        Log.info("Got device token \(hexToken)")
        settings.pushToken = token
        settings.notificationsAllowed = true
    }
    
    func didFailToRegister(_ error: Error) {
        Log.error("Remote notifications registration failure code")// \(error.code) \(error.description)")
        settings.pushToken = PushToken(token: PimpSettings.NoPushTokenValue)
        settings.notificationsAllowed = false
    }
    
    func handleNotification(_ app: UIApplication, data: [AnyHashable: Any]) {
        Log.info("Handling notification")
        if let tag = data["tag"] as? String,
            let cmd = data["cmd"] as? String,
            let endpoint = settings.endpoints().find({ $0.id == tag }) {
            if cmd == "stop" {
                let library = Libraries.fromEndpoint(endpoint)
                library.stopAlarm(onAlarmError) {
                    Log.info("Stopped alarm playback")
                }
                app.applicationIconBadgeNumber = 0
            }
        }
    }
    
    func onAlarmError(_ error: PimpError) {
        Log.error("Alarm error")
    }
}
