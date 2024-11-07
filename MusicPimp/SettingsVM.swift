protocol SettingsVMLike: ObservableObject {
  var playerName: String { get }
  var libraryName: String { get }
  var currentLimitDescription: String { get }
}

class SettingsVM: SettingsVMLike {
  var playerName: String { playerManager.loadActive().name }
  var libraryName: String { libraryManager.loadActive().name }
  var currentLimitDescription: String {
    let gigs = settings.cacheLimit.toGigs
    return "\(gigs) GB"
  }
}

class PreviewSettingsVM: SettingsVMLike {
  var playerName: String { "player 1" }
  var libraryName: String { "lib 1" }
  var currentLimitDescription: String { "10 GB" }
}
