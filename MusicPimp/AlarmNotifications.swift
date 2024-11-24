class AlarmNotifications {
  let log = LoggerFactory.shared.vc(AlarmNotifications.self)
  
  var settings: PimpSettings { PimpSettings.sharedInstance }
  
  let onToggle: (Bool) async -> Void
  
  init(onToggle: @escaping (Bool) async -> Void) {
    self.onToggle = onToggle
  }
  
  func registerNotifications(_ endpoint: Endpoint) async {
    let granted = await PimpNotifications.sharedInstance.request()
    if granted {
      if let token = settings.pushToken {
        log.info("Registering with previously saved push token...")
        await registerWithToken(token: token, endpoint: endpoint)
      } else {
        log.info("Access granted, but no token available.")
      }
    } else {
      settings.notificationsAllowed = false
      await onToggle(false)
      let error = PimpError.simple("The user did not grant permission to send notifications.")
      onRegisterError(error: error, endpoint: endpoint)
    }
  }
  
  private func onPermission(granted: Bool, endpoint: Endpoint) async {
    if granted {
      if let token = settings.pushToken {
        log.info("Permission granted, registering with \(endpoint.address)")
        await registerWithToken(token: token, endpoint: endpoint)
      } else {
        log.info("Access granted, but no token available.")
      }
    } else {
      settings.notificationsAllowed = false
      await onToggle(false)
      let error = PimpError.simple("The user did not grant permission to send notifications.")
      onRegisterError(error: error, endpoint: endpoint)
    }
  }
  
  private func registerWithToken(token: PushToken, endpoint: Endpoint) async {
    let alarmLibrary = Libraries.fromEndpoint(endpoint)
    do {
      let _ = try await alarmLibrary.registerNotifications(token, tag: endpoint.id)
      let _ = settings.saveNotificationsEnabled(endpoint, enabled: true)
    } catch {
      onRegisterError(error: error, endpoint: endpoint)
    }
  }
  
  private func unregisterNotifications(_ endpoint: Endpoint) async {
    log.info("Unregistering from \(endpoint.address)...")
    let alarmLibrary = Libraries.fromEndpoint(endpoint)
    do {
      let _ = try await alarmLibrary.unregisterNotifications(endpoint.id)
      let _ = self.settings.saveNotificationsEnabled(endpoint, enabled: false)
    } catch {
      onRegisterError(error: error, endpoint: endpoint)
    }
  }

  func onRegisterError(error: Error, endpoint: Endpoint) {
    log.error(error.message)
  }
}
