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

  override func refresh() {
    renderTable("Loading popular tracks...") {
      self.entries = []
    }
    library.popular(0, until: itemsPerLoad).subscribe { (event) in
      switch event {
      case .success(let rs): self.onTopLoaded(rs)
      case .failure(let err): self.onTopError(err)
      }
    }.disposed(by: bag)
  }

  override func loadMore() {
    let oldSize = entries.count
    library.popular(oldSize, until: oldSize + itemsPerLoad).subscribe { (event) in
      switch event {
      case .success(let rs): self.onMoreResults(oldSize, results: rs)
      case .failure(let err): self.onTopError(err)
      }
    }.disposed(by: bag)
  }
}
