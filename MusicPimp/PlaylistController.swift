import Foundation
import UIKit

enum ListMode: Int {
  case popular = 0
  case recent
}

class PlaylistController: BaseMusicController {
  private let log = LoggerFactory.shared.vc(PlaylistController.self)
  let defaultCellKey = "PimpMusicItemCell"
  let itemsPerLoad = 100
  let minItemsRemainingBeforeLoadMore = 20
  var emptyMessage: String {
    switch mode {
    case .popular: return "No popular tracks."
    case .recent: return "No recent tracks."
    }
  }
  var mode: ListMode = .popular
  var recent: [RecentEntry] = []
  var popular: [PopularEntry] = []
  var tracks: [Track] {
    switch mode {
    case .popular: return popular.map { $0.track }
    case .recent: return recent.map { $0.track }
    }
  }
  override var musicItems: [MusicItem] { return tracks }
  private var reloadOnDidAppear = true

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView?.register(
      SnapMainSubCell.self, forCellReuseIdentifier: FeedbackTable.mainAndSubtitleCellKey)
    Task {
      await maybeRefresh(mode)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if reloadOnDidAppear {
      self.reloadTable(feedback: self.tracks.isEmpty ? emptyMessage : nil)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    reloadOnDidAppear = !DownloadUpdater.instance.isEmpty
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let index = indexPath.row
    switch mode {
    case .popular:
      let cell: SnapMainSubCell = loadCell(FeedbackTable.mainAndSubtitleCellKey, index: indexPath)
      decoratePopularCell(cell, track: popular[index])
      cell.accessoryDelegate = self
      return cell
    case .recent:
      let cell: SnapMainSubCell = loadCell(FeedbackTable.mainAndSubtitleCellKey, index: indexPath)
      decorateRecentCell(cell, track: recent[index])
      cell.accessoryDelegate = self
      return cell
    }
  }

  override func tableView(
    _ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath
  ) -> Bool {
    true
  }

  override func tableView(
    _ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath
  ) {
    maybeLoadMore(indexPath.row)
  }

  func maybeLoadMore(_ currentRow: Int) {
    let trackCount = tracks.count
    if currentRow + minItemsRemainingBeforeLoadMore == trackCount {
      Task {
        await loadMore()
      }
    }
  }

  func loadMore() async {
    // TODO DRY by refactoring recent and popular handling into reusable modules
    switch mode {
    case .popular:
      let from = popular.count
      await fetchPopular(from: from, maxItems: itemsPerLoad) { ps in
        self.onMorePopulars(from, populars: ps)
      }
    case .recent:
      let from = recent.count
      await fetchRecent(from: from, maxItems: itemsPerLoad) { rs in
        self.onMoreRecents(from, recents: rs)
      }
    }
  }

  // parent calls this one
  func maybeRefresh(_ targetMode: ListMode) async {
    mode = targetMode
    switch targetMode {
    case .popular:
      withMessage("Loading popular tracks...") {
        self.popular = []
      }
      await fetchPopular(from: 0, maxItems: itemsPerLoad, onPopulars: onPopularsLoaded)
    case .recent:
      withMessage("Loading recent tracks...") {
        self.recent = []
      }
      await fetchRecent(from: 0, maxItems: itemsPerLoad, onRecents: onRecentsLoaded)
    }
  }

  func fetchPopular(from: Int, maxItems: Int, onPopulars: @escaping ([PopularEntry]) -> Void) async
  {
    do {
      let pops = try await library.popular(from, until: from + maxItems)
      onPopulars(pops)
    } catch {
      onPopularError(error)
    }
  }

  func fetchRecent(from: Int, maxItems: Int, onRecents: @escaping ([RecentEntry]) -> Void) async {
    do {
      let recents = try await library.recent(from, until: from + maxItems)
      onRecents(recents)
    } catch {
      onRecentError(error)
    }
  }

  func decorateRecentCell(_ cell: SnapMainSubCell, track: RecentEntry) {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    formatter.doesRelativeDateFormatting = true
    let formattedDate = formatter.string(from: track.timestamp)
    decorateTwoLines(cell, first: track.track.title, second: formattedDate)
  }

  func decoratePopularCell(_ cell: SnapMainSubCell, track: PopularEntry) {
    decorateTwoLines(cell, first: track.track.title, second: "\(track.playbackCount) plays")
  }

  func decorateTwoLines(_ cell: SnapMainSubCell, first: String, second: String) {
    cell.main.text = first
    cell.sub.text = second
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let index = indexPath.row
    Task {
      await limitChecked {
        let track = self.tracks[index]
        _ = await self.playTrack(track)
      }
    }
    tableView.deselectRow(at: indexPath, animated: false)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    self.tracks.count
  }

  override func playTrackAccessoryAction(_ track: Track, row: Int) -> UIAlertAction {
    // starts playback of the selected track, and appends the rest to the playlist
    accessoryAction("Start Playback Here") { _ in
      _ = await self.playTracksChecked(self.tracks.drop(row))
    }
  }

  func onRecentsLoaded(_ recents: [RecentEntry]) {
    withReload(emptyMessage) {
      self.recent = recents
    }
  }

  func onPopularsLoaded(_ populars: [PopularEntry]) {
    withReload(emptyMessage) {
      self.popular = populars
    }
  }

  func onMoreRecents(_ from: Int, recents: [RecentEntry]) {
    onUiThread {
      self.recent = self.appendConditionally(self.recent, from: from, newContent: recents)
      self.onMore(
        from, newRows: recents.count, expectedSize: self.recent.count, expectedMode: .recent)
    }

  }

  func onMorePopulars(_ from: Int, populars: [PopularEntry]) {
    onUiThread {
      self.popular = self.appendConditionally(self.popular, from: from, newContent: populars)
      self.onMore(
        from, newRows: populars.count, expectedSize: self.popular.count, expectedMode: .popular)
    }
  }

  private func onMore(_ from: Int, newRows: Int, expectedSize: Int, expectedMode: ListMode) {
    let rows: [Int] = Array(from..<from + newRows)
    let indexPaths = rows.map { row in IndexPath(item: row, section: 0) }

    if self.mode == expectedMode && (from + newRows) == expectedSize {
      self.tableView.insertRows(at: indexPaths, with: .bottom)
      self.log.info("Updated table with \(indexPaths.count) more items")
    }
  }

  func appendConditionally<T>(_ src: [T], from: Int, newContent: [T]) -> [T] {
    let oldSize = src.count
    if oldSize == from {
      return src + newContent
      //src.appendContentsOf(newContent)
    } else {
      log.info("Not appending because of list size mismatch. Was: \(oldSize), expected \(from)")
      return src
    }
  }

  func onPopularError(_ e: Error) {
    onError(e)
    withMessage("Failed to load popular tracks.") {
      self.popular = []
    }
  }

  func onRecentError(_ e: Error) {
    onError(e)
    withMessage("Failed to load recent tracks.") {
      self.recent = []
    }
  }
}
