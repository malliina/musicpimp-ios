import Foundation
import RxSwift

class MostRecentList: TopListController<RecentEntry> {
  let MostRecentCellKey = "MostRecentCell"
  override var header: String { "Most Recent" }
  override var emptyMessage: String { "No recent tracks." }
  override var failedToLoadMessage: String { "Failed to load recent tracks." }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView?.register(MostRecentCell.self, forCellReuseIdentifier: MostRecentCellKey)
  }

  override func cellFor(track: RecentEntry, indexPath: IndexPath) -> UITableViewCell {
    let cell: MostRecentCell = loadCell(MostRecentCellKey, index: indexPath)
    decorate(cell: cell, track: track)
    cell.accessoryDelegate = self
    return cell
  }

  func decorate(cell: MostRecentCell, track: RecentEntry) {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    formatter.doesRelativeDateFormatting = true
    let formattedDate = formatter.string(from: track.timestamp)
    cell.fill(main: track.track.title, subLeft: track.track.artist, subRight: formattedDate)
  }

  override func refresh() async {
    entries = []
    reloadTable(feedback: "Loading recent tracks...")
    do {
      let rs = try await library.recent(0, until: itemsPerLoad)
      onTopLoaded(rs)
    } catch {
      onTopError(error)
    }
  }

  override func loadMore() async {
    let oldSize = entries.count
    do {
      let rs = try await library.recent(oldSize, until: oldSize + itemsPerLoad)
      onMoreResults(oldSize, results: rs)
    } catch {
      onTopError(error)
    }
  }
}
