protocol SettingsVMLike: ObservableObject {
  var playerName: String { get }
  var libraryName: String { get }
  var currentLimit: StorageSize { get }
  func load() async
}

extension SettingsVMLike {
  var currentLimitText: String {
    let gigs = currentLimit.toGigs
    return "\(gigs) GB"
  }
}

class SettingsVM: SettingsVMLike {
  var playerName: String { playerManager.loadActive().name }
  var libraryName: String { libraryManager.loadActive().name }
  
  @Published var currentLimit: StorageSize = PimpSettings.sharedInstance.cacheLimit
  
  @MainActor func load() async {
    on(limit: settings.cacheLimit)
  }
  
  @MainActor private func on(limit: StorageSize) {
    self.currentLimit = limit
  }
}

class PreviewSettingsVM: SettingsVMLike {
  var playerName: String { "player 1" }
  var libraryName: String { "lib 1" }
  var currentLimit: StorageSize { StorageSize(gigs: 10) }
  
  func load() async {}
}
