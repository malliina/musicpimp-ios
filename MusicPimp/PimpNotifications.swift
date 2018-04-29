//
//  PimpNotifications.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 29/03/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation
import UserNotifications
import RxSwift

open class PimpNotifications {
    let log = LoggerFactory.shared.system(PimpNotifications.self)
    open static let sharedInstance = PimpNotifications()
    
    let settings = PimpSettings.sharedInstance
    
    let bag = DisposeBag()
    
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
        do {
            let tag: String = try Json.readMapOrFail(data, "tag")
            let cmd: String = try Json.readMapOrFail(data, "cmd")
            guard let endpoint = settings.endpoints().find({ $0.id == tag }) else { throw JsonError.invalid("tag", tag) }
            if cmd == "stop" {
                log.info("Stopping alarm playback...")
                let library = Libraries.fromEndpoint(endpoint)
                library.stopAlarm().subscribe({ (event) in
                    switch event {
                    case .next(_): self.log.info("Stopped alarm playback.")
                    case .error(_): self.log.info("Failed to stop alarm playback.")
                    case .completed: ()
                    }
                }).disposed(by: bag)
                app.applicationIconBadgeNumber = 0
            } else {
                log.error("Unknown command in notification: '\(cmd)'.")
            }
        } catch let json as JsonError {
            log.error("Failed to validate notification payload. \(json.message)")
        } catch _ {
            log.error("Failed to handle notification, unknown error")
        }
    }
    
    func onAlarmError(_ error: PimpError) {
        log.error("Alarm error")
    }
}
