import Foundation
import RxSwift
import UserNotifications

open class PimpNotifications {
  let log = LoggerFactory.shared.system(PimpNotifications.self)
  static let sharedInstance = PimpNotifications()

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
    log.error("Remote notifications registration failure \(error.localizedDescription)")
    disableNotifications()
  }

  private func disableNotifications() {
    settings.pushToken = PushToken(token: PimpSettings.NoPushTokenValue)
    settings.notificationsAllowed = false
  }

  func handleNotification(_ app: UIApplication, data: [AnyHashable: Any]) {
    do {
      guard let tag = data["tag"] as? String else {
        throw PimpError.simple("Key 'tag' is not a String in payload.")
      }
      guard let cmd = data["cmd"] as? String else {
        throw PimpError.simple("Key 'cmd' is not a String in payload.")
      }
      guard let endpoint = settings.endpoints().find({ $0.id == tag }) else {
        throw JsonError.invalid("tag", tag)
      }
      if cmd == "stop" {
        let library = Libraries.fromEndpoint(endpoint)
        library.stopAlarm().subscribe({ (event) in
          switch event {
          case .success(_): self.log.info("Stopped alarm playback.")
          case .failure(let err):
            self.log.info("Failed to stop alarm playback. \(err.localizedDescription)")
          }
        }).disposed(by: bag)
        app.applicationIconBadgeNumber = 0
      } else {
        log.error("Unknown command in notification: '\(cmd)'.")
      }
    } catch let json as JsonError {
      log.error("Failed to validate notification payload. \(json.message)")
    } catch let err as PimpError {
      log.error("Failed to handle notification. \(err.message)")
    } catch {
      log.error("Failed to handle notification, unknown error.")
    }
  }

  func onAlarmError(_ error: PimpError) {
    log.error("Alarm error")
  }
}
