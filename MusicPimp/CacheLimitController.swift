import Foundation

class CacheLimitController: BaseTableController {
  let gigOptions: [Int] = [1, 2, 5, 10, 20, 50, 100, 500]
  var sizes: [StorageSize] { gigOptions.map { (gB) -> StorageSize in StorageSize(gigs: gB) } }
  var current: StorageSize { settings.cacheLimit }
  let currentCacheCell = "CurrentCacheLimit"
  let cacheCell = "CacheLimit"

  override func viewDidLoad() {
    super.viewDidLoad()
    Task {
      for await limit in settings.$cacheLimitChanged.nonNilValues() {
        onCacheLimitChanged(limit)
      }
    }
    [currentCacheCell, cacheCell].forEach { (id) in
      registerCell(reuseIdentifier: id)
    }
  }

  func onCacheLimitChanged(_ newLimit: StorageSize) {
    reloadTable()
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let row = indexPath.row
    let cellGigs = gigOptions[row]
    let cellSize = sizes[row]
    let isCurrent = cellSize == current
    let prototype = isCurrent ? currentCacheCell : cacheCell
    let accessory =
      isCurrent ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
    let cell = tableView.dequeueReusableCell(withIdentifier: prototype, for: indexPath)
    cell.accessoryType = accessory
    cell.textLabel?.tintColor = PimpColors.shared.titles
    cell.textLabel?.textColor = PimpColors.shared.titles
    cell.textLabel?.text = "\(cellGigs) GB"
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let size = sizes[indexPath.row]
    settings.cacheLimit = size
    tableView.deselectRow(at: indexPath, animated: false)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    gigOptions.count
  }
}
