import Foundation
import SwiftUI
import UIKit

class RowSpec {
  static let empty = RowSpec(reuseIdentifier: "", text: "")
  let reuseIdentifier: String
  let text: String

  init(reuseIdentifier: String, text: String) {
    self.reuseIdentifier = reuseIdentifier
    self.text = text
  }
}

class SettingsController: CacheInfoController, EditEndpointDelegate, PlayerEndpointDelegate,
  LibraryEndpointDelegate, AccessoryDelegate
{
  private let log = LoggerFactory.shared.vc(SettingsController.self)
  let detailId = "DetailedCell"
  let sectionHeaderHeight: CGFloat = 44
  let playbackDeviceId = "PlaybackDevice"
  let musicSourceId = "MusicSource"
  let cacheId = "Cache"
  let alarmId = "Alarm"
  let aboutId = "About"
  let creditsId = "Credits"

  let libraryManager = LibraryManager.sharedInstance
  let playerManager = PlayerManager.sharedInstance

  var activeLibrary: Endpoint { libraryManager.loadActive() }
  var activePlayer: Endpoint { playerManager.loadActive() }

  let sourcePicker = UIPickerView()
  let listener = EndpointsListener()

  override func viewDidLoad() {
    super.viewDidLoad()
    [playbackDeviceId, musicSourceId, cacheId, alarmId, aboutId, creditsId].forEach { id in
      self.tableView?.register(DisclosureCell.self, forCellReuseIdentifier: id)
    }
    Task {
      for await enabled in settings.$cacheEnabledChanged.nonNilValues() {
        onCacheEnabledChanged(enabled)
      }
    }
    listener.players = self
    listener.libraries = self
    listener.subscribe()
    navigationItem.title = "SETTINGS"
    navigationController?.navigationBar.titleTextAttributes = [
      NSAttributedString.Key.font: colors.titleFont
    ]
  }

  func endpointAddedOrUpdated(_ endpoint: Endpoint) {
    reloadTable()
  }

  func onLibraryUpdated(to newLibrary: Endpoint) {
    reloadTable()
  }

  func onPlayerUpdated(to newPlayer: Endpoint) {
    reloadTable()
  }

  fileprivate func onCacheEnabledChanged(_ newEnabled: Bool) {
    reloadTable()
  }

  override func onCacheLimitChanged(_ newLimit: StorageSize) {
    reloadTable()
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let spec = specForRow(indexPath: indexPath) ?? RowSpec(reuseIdentifier: "", text: "")
    let cell: DisclosureCell = loadCell(spec.reuseIdentifier, index: indexPath)
    cell.title.text = spec.text
    cell.detail.text = textForIdentifier(spec.reuseIdentifier)
    cell.accessoryDelegate = self
    return cell
  }

  func specForRow(indexPath: IndexPath) -> RowSpec? {
    switch indexPath.section {
    case 0:
      switch indexPath.row {
      case 0: return RowSpec(reuseIdentifier: musicSourceId, text: "Music source")
      case 1: return RowSpec(reuseIdentifier: playbackDeviceId, text: "Play music on")
      default: return nil
      }
    case 1: return RowSpec(reuseIdentifier: cacheId, text: "Cache")
    case 2: return RowSpec(reuseIdentifier: alarmId, text: "Alarms")
    case 3:
      switch indexPath.row {
      case 0: return RowSpec(reuseIdentifier: aboutId, text: "MusicPimp Premium")
      case 1: return RowSpec(reuseIdentifier: creditsId, text: "Credits")
      default: return nil
      }
    default: return nil
    }
  }

  fileprivate func textForIdentifier(_ reuseIdentifier: String) -> String {
    return switch reuseIdentifier {
    case musicSourceId: activeLibrary.name
    case playbackDeviceId: activePlayer.name
    case cacheId: settings.cacheEnabled ? currentLimitDescription : "off"
    default: ""
    }
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    4
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return switch section {
    case 0: 2
    case 1: 1
    case 2: 1
    case 3: 2
    default: 0
    }
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
  {
    return switch section {
    case 0: "PLAYBACK"
    case 1: "STORAGE"
    case 2: "ALARM CLOCK"
    case 3: "ABOUT"
    default: nil
    }
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int)
    -> CGFloat
  {
    sectionHeaderHeight
  }

  override func tableView(
    _ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int
  ) {
    if let v = view as? UITableViewHeaderFooterView {
      v.tintColor = colors.background
      v.textLabel?.font = v.textLabel?.font.withSize(12)
      v.textLabel?.textAlignment = .center
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let dest = destinationFor(indexPath: indexPath) {
      if let navCtrl = navigationController {
        navCtrl.pushViewController(dest, animated: true)
      } else {
        log.info("No nav controller, no navigation.")
      }
    } else {
      log.info("Selected row at \(indexPath.row), but got no destination.")
    }
    tableView.deselectRow(at: indexPath, animated: false)
    tableView.reloadRows(at: [indexPath], with: .none)
  }

  func accessoryTapped(_ sender: UIButton, event: AnyObject) {
    if let indexPath = clickedIndexPath(event), let dest = destinationFor(indexPath: indexPath) {
      self.navigationController?.pushViewController(dest, animated: true)
    }
  }

  func destinationFor(indexPath: IndexPath) -> UIViewController? {
    if let id = tableView.cellForRow(at: indexPath)?.reuseIdentifier {
      switch id {
      case musicSourceId:
        let dest = SourceSettingController()
        dest.delegate = self
        return dest
      case playbackDeviceId:
        let dest = PlayerSettingController()
        dest.delegate = self
        return dest
      case cacheId:
        return CacheTableController()
      case alarmId:
        return AlarmsController()
      case aboutId:
        return IAPViewController()
      case creditsId:
        let hc = UIHostingController(rootView: CreditsView())
        hc.title = "CREDITS"
        return hc
      default:
        return nil
      }
    }
    return nil
  }
}
