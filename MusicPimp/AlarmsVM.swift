import Combine

protocol AlarmsSource {
  var player: Published<Endpoint?>.Publisher { get }
  
  func alarms(endpoint: Endpoint) async -> [Alarm]
}

class PimpAlarmsSource: AlarmsSource {
  var player: Published<Endpoint?>.Publisher {
    PimpSettings.sharedInstance.$defaultAlarmEndpointChanged
  }
  func alarms(endpoint: Endpoint) async -> [Alarm] {
    let lib = Libraries.fromEndpoint(endpoint)
    return (try? await lib.alarms()) ?? []
  }
}

extension AlarmsSource {
  func load() async -> [Alarm] {
    if let endpoint = PimpSettings.sharedInstance.defaultAlarmEndpointChanged {
      return await alarms(endpoint: endpoint)
    } else {
      return []
    }
  }
}

class AlarmsVM: SelectEndpointVM {
  static let shared = AlarmsVM(source: PlayerManager.sharedInstance, alarmsSource: PimpAlarmsSource())
  let log = LoggerFactory.shared.pimp(AlarmsVM.self)
  
  private var cancellables: Set<Task<(), Never>> = []
  
  let alarmsSource: AlarmsSource
  @Published var endpoint: Endpoint?
  @Published var alarms: [Alarm] = []
  @Published var selectedId: String = ""
  
  @Published var searchText: String = ""
  @Published var searchResult: Outcome<SearchResult> = Outcome.Idle
  
  @Published var isNotificationsEnabled: Bool = false
  @Published var notificationsFeedback: String? = nil
  
  private var a: AlarmNotifications? = nil
  
  var library: LibraryType {
    if let endpoint = endpoint {
      return Libraries.fromEndpoint(endpoint)
    } else {
      return LocalLibrary.sharedInstance
    }
  }
  var player: PlayerType {
    if let endpoint = endpoint {
      return Players.sharedInstance.fromEndpoint(endpoint)
    } else {
      return LocalPlayer.sharedInstance
    }
  }
  
  init(source: EndpointSource, alarmsSource: AlarmsSource, initialAlarms: [Alarm] = []) {
    self.alarmsSource = alarmsSource
    self.alarms = initialAlarms
    super.init(source: source)
    let task = Task {
      for await e in alarmsSource.player.nonNilValues() {
        let alarms = await alarmsSource.load()
        await on(endpoint: e, alarms: alarms)
      }
    }
    cancellables = [task]
  }
  
  func select(id: String) async {
    if let newPlayer = savedEndpoints.find({$0.id == id}), id != endpoint?.id {
      settings.saveDefaultNotificationsEndpoint(newPlayer, publish: true)
    }
  }
  
  func save(a: Alarm) async {
    do {
      let _ = try await library.saveAlarm(a)
      await load()
    } catch {
      log.error("Failed to save alarm for \(a.track.title). \(error)")
    }
  }
  
  func remove(id: AlarmID) async {
    do {
      let _ = try await library.deleteAlarm(id)
      await load()
    } catch {
      log.info("Failed to delete alarm \(id). \(error)")
    }
  }
  
  func load() async {
    let alarms = await alarmsSource.load()
    await on(alarms: alarms)
  }
  
  func search(term: String) async {
    let results =
      if term.isEmpty {
        Outcome<SearchResult>.Idle
      } else {
        await fetch(term: term)
      }
    await update(search: results)
  }
  
  func toggle(notificationsEnabled: Bool) async {
    if let endpoint = endpoint {
      log.info("Toggled notifications to \(notificationsEnabled)")
      let n = AlarmNotifications { isOn in
        self.log.info("No access...")
        await self.on(notificationsEnabled: isOn)
      }
      a = n
      await n.registerNotifications(endpoint)
    }
  }
  
  private func fetch(term: String) async -> Outcome<SearchResult> {
    if term.isEmpty {
      return Outcome.Idle
    } else {
//      log.info("Searching '\(term)'...")
      do {
        let results = try await library.search(term)
        return .Loaded(data: SearchResult(term: term, tracks: results))
      } catch {
        log.error("Search of '\(term)' failed. \(error)")
        return Outcome.Err(error: error)
      }
    }
  }
  
  @MainActor func update(search: Outcome<SearchResult>) {
    self.searchResult = search
  }
  
  @MainActor func on(alarms: [Alarm]) {
    self.alarms = alarms
  }
  
  @MainActor func on(endpoint: Endpoint, alarms: [Alarm]) {
    self.endpoint = endpoint
    self.selectedId = endpoint.id
    self.alarms = alarms
    self.isNotificationsEnabled = settings.notificationsEnabled(endpoint)
    self.notificationsFeedback = nil
  }
  
  @MainActor func on(notificationsEnabled: Bool) {
    log.info("Setting toggle to \(notificationsEnabled)")
    self.isNotificationsEnabled = notificationsEnabled
    if !notificationsEnabled {
      self.notificationsFeedback = "Open Settings and authorize this app to send notifications."
    }
  }
}
