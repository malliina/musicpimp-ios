import Foundation

class MostPopularList: TopListController<PopularEntry> {
  let MostPopularCellKey = "MostPopularCell"
  override var header: String { "Most Popular" }
  override var emptyMessage: String { "No popular tracks." }
  override var failedToLoadMessage: String { "Failed to load popular tracks." }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView?.register(MostPopularCell.self, forCellReuseIdentifier: MostPopularCellKey)
  }

  override func cellFor(track: PopularEntry, indexPath: IndexPath) -> UITableViewCell {
    let cell: MostPopularCell = loadCell(MostPopularCellKey, index: indexPath)
    cell.fill(
      main: track.track.title, subLeft: track.track.artist, subRight: "\(track.playbackCount) plays"
    )
    cell.accessoryDelegate = self
    return cell
  }

  @MainActor
  override func refresh() async {
    entries = []
    reloadTable(feedback: "Loading popular tracks...")
    do {
      let rs = try await library.popular(0, until: itemsPerLoad)
      onTopLoaded(rs)
    } catch {
      onTopError(error)
    }
  }

  override func loadMore() async {
    let oldSize = entries.count
    do {
      let rs = try await library.popular(oldSize, until: oldSize + itemsPerLoad)
      onMoreResults(oldSize, results: rs)
    } catch {
      onTopError(error)
    }
  }
}
