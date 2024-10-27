class PopularData: TopData<PopularEntry> {
  static let shared = PopularData()
  override func fetch(from: Int) async throws -> [PopularEntry] {
    try await library.popular(from, until: size + itemsPerLoad)
  }
}

class RecentData: TopData<RecentEntry> {
  static let shared = RecentData()
  override func fetch(from: Int) async throws -> [RecentEntry] {
    try await library.recent(from, until: size + itemsPerLoad)
  }
}

class TopData<T>: ObservableObject {
  let itemsPerLoad = 100
  var libraryManager: LibraryManager { LibraryManager.sharedInstance }
  var library: LibraryType { libraryManager.libraryUpdated }

  @Published var results: Outcome<[T]> = Outcome.Idle
  @Published var hasMore: Bool = false
  var size: Int {
    results.value()?.count ?? 0
  }
  private var loaded: Date? = nil
  var appearAction: AppearAction {
    if let loaded = loaded {
      if loaded > libraryManager.latestUpdate {
        .Noop
      } else {
        .Reload
      }
    } else {
      .Reload
    }
  }

  func load() async {
    loaded = Date.now
    await update(results: .Loading, hasMore: false)
    await loadBatch()
  }

  func loadBatch() async {
    do {
      let batch = try await fetch(from: size)
      let old = results.value() ?? []
      await update(results: .Loaded(data: old + batch), hasMore: batch.count == itemsPerLoad)
    } catch {
      await update(results: .Err(error: error), hasMore: false)
    }
  }

  func fetch(from: Int) async throws -> [T] {
    []
  }

  @MainActor
  private func update(results: Outcome<[T]>, hasMore: Bool) {
    self.results = results
    self.hasMore = hasMore
  }
}

//class StaticPopularData: TopData<PopularEntry> {
//  private let log = LoggerFactory.shared.pimp(StaticPopularData.self)
//  let data = Array(1...100).map { int in
//    PopularEntry(track: PreviewLibrary.makeTrack(num: int), playbackCount: int)
//  }
//
//  override func fetch(from: Int) async throws -> [PopularEntry] {
//    log.info("Loading \(itemsPerLoad) items from \(from)...")
//    try? await Task.sleep(nanoseconds: 1_000_000_000)
//    return data.drop(from).take(itemsPerLoad)
//  }
//}
