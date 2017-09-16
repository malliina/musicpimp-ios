//
//  PimpNotifications.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 29/03/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation
import UserNotifications

open class PimpNotifications {
    let log = LoggerFactory.pimp("PimpNotifications", category: "System")
    open static let sharedInstance = PimpNotifications()
    
    let settings = PimpSettings.sharedInstance
    
    func initNotifications(_ application: UIApplication) {
        // the playback notification is displayed as an alert to the user, so we must call this
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            if !granted {
                self.log.info("The user did not grant permission to send notifications")
                self.disableNotifications()
            } else {
            }
        }
        log.info("Registering with APNs...")
        // registers with APNs
        application.registerForRemoteNotifications()
    }
    
    func didRegister(_ deviceToken: Data) {
        let hexToken = deviceToken.hexString()
        let token = PushToken(token: hexToken)
        log.info("Got device token \(hexToken)")
        settings.pushToken = token
        settings.notificationsAllowed = true
    }
    
    func didFailToRegister(_ error: Error) {
        log.error("Remote notifications registration failure")
        disableNotifications()
    }
    
    private func disableNotifications() {
        settings.pushToken = PushToken(token: PimpSettings.NoPushTokenValue)
        settings.notificationsAllowed = false
    }
    
    func handleNotification(_ app: UIApplication, data: [AnyHashable: Any]) {
        log.info("Handling notification")
        if let tag = data["tag"] as? String,
            let cmd = data["cmd"] as? String,
            let endpoint = settings.endpoints().find({ $0.id == tag }) {
            if cmd == "stop" {
                let library = Libraries.fromEndpoint(endpoint)
                library.stopAlarm(onAlarmError) {
                    self.log.info("Stopped alarm playback")
                }
                app.applicationIconBadgeNumber = 0
            }
        }
    }
    
    func onAlarmError(_ error: PimpError) {
        log.error("Alarm error")
    }
}
