import Foundation

class CacheTableController: CacheInfoController {
  private let log = LoggerFactory.shared.pimp(CacheTableController.self)

  let CacheEnabledCell = "CacheEnabledCell", CacheSizeCell = "CacheSizeCell",
    CurrentUsageCell = "CurrentUsageCell", DeleteCacheCell = "DeleteCacheCell",
    DeleteCustom = "DeleteCustom", EmptyCell = "EmptyCell"

  let onOffSwitch = UISwitch(frame: CGRect.zero)

  let sectionFooterIdentifier = "SectionFooter"
  static let footerText =
    "Deletes locally cached tracks when the specified cache size limit is exceeded."
  let headerLabel = PimpLabel.footerLabel(CacheTableController.footerText)

  var footerInset: CGFloat { tableView.layoutMargins.left }

  var library: LocalLibrary { LocalLibrary.sharedInstance }

  @Published var usedStorage = StorageSize.Zero

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.title = "OFFLINE STORAGE"
    [CacheEnabledCell, CurrentUsageCell, DeleteCacheCell].forEach { id in
      self.tableView?.register(DetailedCell.self, forCellReuseIdentifier: id)
    }
    self.tableView?.register(DisclosureCell.self, forCellReuseIdentifier: CacheSizeCell)
    [DeleteCustom, EmptyCell].forEach { (id) in
      registerCell(reuseIdentifier: id)
    }
    tableView.register(
      UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: sectionFooterIdentifier)
    onOffSwitch.addTarget(
      self, action: #selector(CacheTableController.didToggleCache(_:)),
      for: UIControl.Event.valueChanged)
    onOffSwitch.isOn = settings.cacheEnabled
    Task {
      for await storage in $usedStorage.values {
        onUiThread {
          self.tableView.reloadData()
        }
      }
    }
    calculateCacheUsage()
  }

  override func viewWillTransition(
    to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animateAlongsideTransition(in: self.tableView, animation: nil) { _ in
      self.headerLabel.snp.remakeConstraints { make in
        make.leading.trailing.equalToSuperview().inset(self.footerInset)
      }
      self.tableView.reloadData()
    }
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    3
  }

  override func onCacheLimitChanged(_ newSize: StorageSize) {
    log.info("Updating cache limit UI to \(newSize)")
    Util.onUiThread {
      self.tableView.reloadData()
    }
  }

  fileprivate func calculateCacheUsage() {
    DispatchQueue.global(qos: .background).async {
      self.usedStorage = self.library.size
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let spec = specForRow(indexPath: indexPath) ?? RowSpec(reuseIdentifier: EmptyCell, text: "")
    switch spec.reuseIdentifier {
    case CacheEnabledCell:
      let cell = basicCell(spec: spec, indexPath: indexPath)
      cell.accessoryView = onOffSwitch
      return cell
    case CacheSizeCell:
      let cell: DisclosureCell = loadCell(spec.reuseIdentifier, index: indexPath)
      cell.title.text = spec.text
      cell.detail.text = currentLimitDescription
      return cell
    case CurrentUsageCell:
      let cell = basicCell(spec: spec, indexPath: indexPath)
      cell.detailTextLabel?.text = usedStorage.shortDescription
      return cell
    case DeleteCustom:
      let cell = basicCell(spec: spec, indexPath: indexPath)
      if let label = cell.textLabel {
        label.textColor = colors.deletion
        label.textAlignment = .center
        label.highlightedTextColor = colors.deletionHighlighted
      }
      return cell
    default:
      return identifiedCell(EmptyCell, index: indexPath)
    }
  }

  func basicCell(spec: RowSpec, indexPath: IndexPath) -> UITableViewCell {
    let cell = identifiedCell(spec.reuseIdentifier, index: indexPath)
    cell.textLabel?.text = spec.text
    cell.textLabel?.textColor = colors.titles
    return cell
  }

  func specForRow(indexPath: IndexPath) -> RowSpec? {
    let row = indexPath.row
    return switch indexPath.section {
    case 0:
      switch row {
      case 0: RowSpec(reuseIdentifier: CacheEnabledCell, text: "Automatic Offline Storage")
      default: nil
      }
    case 1:
      switch row {
      case 0: RowSpec(reuseIdentifier: CacheSizeCell, text: "Size Limit")
      case 1: RowSpec(reuseIdentifier: CurrentUsageCell, text: "Current Usage")
      default: nil
      }
    case 2:
      switch row {
      case 0: RowSpec(reuseIdentifier: DeleteCustom, text: "Delete Offline Storage")
      default: nil
      }
    default:
      nil
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return switch section {
    case 0: 1
    case 1: 2
    case 2: 1
    default: 0
    }
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
  {
    return if section == 0 {
      footerView(identifier: sectionFooterIdentifier, content: headerLabel)
    } else {
      super.tableView(tableView, viewForFooterInSection: section)
    }
  }

  override func tableView(
    _ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int
  ) {
    if let v = view as? UITableViewHeaderFooterView {
      v.tintColor = colors.background
    }
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int)
    -> CGFloat
  {
    headerLabel.tableHeaderHeight(tableView)
  }

  @objc func didToggleCache(_ uiSwitch: UISwitch) {
    let isOn = uiSwitch.isOn
    settings.cacheEnabled = isOn
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)
    //        tableView.deselectRow(at: indexPath, animated: false)
    if let reuseIdentifier = cell?.reuseIdentifier {
      switch reuseIdentifier {
      case CacheSizeCell:
        self.navigationController?.pushViewController(CacheLimitController(), animated: true)
      case DeleteCustom:
        deleteCache()
        break
      default:
        break
      }
    }
  }

  private func deleteCache() {
    Task {
      let _ = await library.deleteContents()
      log.info("Done")
      calculateCacheUsage()
    }
  }
}

extension UITableViewController {
  func footerView(identifier: String, content: UILabel) -> UITableViewHeaderFooterView? {
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier)
    content.autoresizingMask = .flexibleHeight
    view?.contentView.addSubview(content)
    content.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview().inset(tableView.layoutMargins.left)
      make.topMargin.equalToSuperview().offset(PimpLabel.headerTopMargin)
    }
    view?.contentView.backgroundColor = PimpColors.shared.background
    return view
  }
}
