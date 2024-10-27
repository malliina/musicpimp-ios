enum AppearAction {
  case Dismiss, Reload, Noop
}

protocol LibraryVMLike: ObservableObject, Playbacks {
  var isLocalLibrary: Bool { get }
  var appearAction: AppearAction { get }
  var isRoot: Bool { get }
  var folder: Outcome<MusicFolder> { get }
  var searchResult: Outcome<SearchResult> { get }
  var searchText: String { get set }
  
  func load() async
  func search(term: String) async
}

enum Outcome<T> {
  case Idle
  case Loading
  case Loaded(data: T)
  case Err(error: Error)
  
  func value() -> T? {
    switch self {
    case .Loaded(let data): return data
    default: return nil
    }
  }
}

struct SearchResult {
  let term: String
  let tracks: [Track]
}

struct MusicData {
  let folder: MusicFolder
  let search: SearchResult?
}

class PremiumState: ObservableObject {
  static let shared = PremiumState()
  
  @Published var isPremiumSuggestion: Bool = false
  
  func limitChecked<T>(_ code: () async -> T) async -> T? {
    if Limiter.sharedInstance.isWithinLimit() {
      return await code()
    } else {
      await suggestPremium()
      return nil
    }
  }
  
  @MainActor
  private func suggestPremium() {
    isPremiumSuggestion = true
  }
}

class LibraryVM: LibraryVMLike {
  let log = LoggerFactory.shared.pimp(LibraryVM.self)
  let id: FolderID?
  
  let controls = PlaybackControls.shared
  
  var libraryManager: LibraryManager { LibraryManager.sharedInstance }
  var library: LibraryType { libraryManager.libraryUpdated }
  
  @Published var folder: Outcome<MusicFolder> = Outcome.Idle
  @Published var searchResult: Outcome<SearchResult> = Outcome.Idle
  @Published var searchText: String = ""
  
  var isLocalLibrary: Bool { library.isLocal }
  private var loaded: Date? = nil
  var isRoot: Bool { id == nil }
  var appearAction: AppearAction {
    if let loaded = loaded {
      if loaded > libraryManager.latestUpdate {
        .Noop
      } else if isRoot {
        .Reload
      } else {
        .Dismiss
      }
    } else {
      .Reload
    }
  }
  
  init(id: FolderID?) {
    self.id = id
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
  
  func load() async {
    loaded = Date.now
    await load(id)
  }
  
  private func load(_ id: FolderID?) async {
    let idStr = id?.value ?? "root"
    await update(state: .Loading)
    do {
      let data =
        if let id = id {
          try await library.folder(id)
        } else {
          try await library.rootFolder()
        }
      let describe = id == nil ? "root" : data.folder.title
      log.info("Loaded \(describe), updating view...")
      await update(state: .Loaded(data: data))
    } catch {
      log.error("Failed to load \(idStr). \(error)")
      await update(state: .Err(error: error))
    }
  }
  
  @MainActor func update(state: Outcome<MusicFolder>) {
    folder = state
  }
  
  @MainActor func update(search: Outcome<SearchResult>) {
    self.searchResult = search
  }
  
  func play(_ item: MusicItem) async {
    await controls.play(item)
  }
  func add(_ item: MusicItem) async {
    await controls.add(item)
  }
  func download(_ item: MusicItem) async {
    await controls.download(item)
  }
}

class PreviewLibrary: LibraryVMLike {
  var appearAction: AppearAction = .Noop
  var isRoot: Bool = true
  var isPremiumSuggestion: Bool = false
  var searchText: String = ""
  var searchResults: [Track]? = nil
  var isLocalLibrary: Bool { true }
  static let track1 = makeTrack(num: 1)
  static let track2 = makeTrack(num: 2)
  static func makeTrack(num: Int) -> Track {
    Track(id: TrackID(id: "t\(num)"), title: "Best track \(num)", album: "Album \(num)", artist: "Artist \(num)", duration: 14.seconds, path: "f1/t\(num)", size: 1213.bytes!, url: URL(string: "https://www.google.com/\(num)")!)
  }
  static let musicFolder = MusicFolder(folder: Folder(id: FolderID(id: "id"), title: "root", path: "root"), folders: [
    Folder(id: FolderID(id: "id1"), title: "Folder 1", path: "f1"),
    Folder(id: FolderID(id: "id2"), title: "Folder 2", path: "f2")
  ], tracks: [ track1, track2 ])
  let folder = Outcome.Loaded(data: musicFolder)
  let searchResult: Outcome<SearchResult> = Outcome.Idle
  
  func load() async {}
  func search(term: String) async {}
  
  func play(_ item: MusicItem) async {}
  func add(_ item: MusicItem) async {}
  func download(_ item: MusicItem) async {}
}
