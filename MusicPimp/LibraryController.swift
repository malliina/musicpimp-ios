import Foundation
import RxSwift
import UIKit

class LibraryController: SearchableMusicController, TrackEventDelegate {
  private let log = LoggerFactory.shared.vc(LibraryController.self)
  static let LIBRARY = "library", PLAYER = "player"
  let loadingMessage = "Loading..."
  let noTracksMessage = "No tracks."

  var folder: MusicFolder = MusicFolder.empty
  override var musicItems: [MusicItem] { folder.items }
  var selected: Folder? = nil

  var header: UIView? = nil

  fileprivate var downloadUpdates: Task<(), Never>? = nil
  private var reloadOnDidAppear = false
  let listener = PlaybackListener()

  var isFirstLoad = true
  private var libraryIdOnDisappear: String = LibraryManager.sharedInstance.libraryUpdated.id

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.tableHeaderView = self.searchController.searchBar
    self.tableView.contentOffset = CGPoint(
      x: 0, y: self.searchController.searchBar.frame.size.height)
    downloadUpdates = Task {
      for await trackProgress in DownloadUpdater.instance.$progress.nonNilValues() {
        onProgress(track: trackProgress)
      }
    }
    setFeedback(loadingMessage)
    listener.tracks = self
    Task {
      await reloadData()
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if reloadOnDidAppear {
      reloadTable(feedback: computeMessage(folder))
    }
    listener.subscribe()
    if libraryIdOnDisappear != libraryManager.libraryUpdated.id {
      Task {
        await reloadData()
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillAppear(animated)
    listener.unsubscribe()
    if !DownloadUpdater.instance.isEmpty {
      reloadOnDidAppear = true
    }
    libraryIdOnDisappear = libraryManager.libraryUpdated.id
  }

  func stopUpdates() {
    downloadUpdates?.cancel()
    downloadUpdates = nil
  }

  private func reloadData() async {
    do {
      if let folder = selected {
        try await loadFolder(folder.id)
      } else {
        try await loadRoot()
      }
    } catch {
      onLoadError(error)
    }
  }

  @MainActor
  func onTrackChanged(_ track: Track?) {
    onUiThread {
      // updates any highlighted row
      self.reloadTableData()
      // why?
      self.view.setNeedsUpdateConstraints()
    }
  }

  func loadFolder(_ id: FolderID) async throws {
    let folder = try await library.folder(id)
    onFolder(folder)
  }

  func loadRoot() async throws {
    let root = try await library.rootFolder()
    log.info("Loaded \(root.folders.count) root folders with library \(library.id)...")
    onFolder(root)
  }

  func suggestAddMusicSource() {
    let sheet = UIAlertController(
      title: "Connect to MusicPimp",
      message:
        "To obtain music, connect to a MusicPimp server. Download the server from musicpimp.org.",
      preferredStyle: .alert)
    let musicSourceAction = UIAlertAction(title: "Add server", style: .default) { _ in
      self.present(
        UINavigationController(rootViewController: EditEndpointController()), animated: true,
        completion: nil)
    }
    let notNowAction = UIAlertAction(title: "Not now", style: .cancel, handler: nil)
    sheet.addAction(musicSourceAction)
    sheet.addAction(notNowAction)
    if let popover = sheet.popoverPresentationController {
      popover.sourceView = self.view
    }
    self.present(sheet, animated: true, completion: nil)
  }

  func onFolder(_ f: MusicFolder) {
    folder = f
    reloadTable(feedback: computeMessage(folder))
    if folder.items.isEmpty {
      let hasRemoteSources = libraryManager.endpoints().exists { (e) -> Bool in
        e.id != Endpoint.Local.id
      }
      if !hasRemoteSources && isFirstLoad {
        suggestAddMusicSource()
      } else {
        log.info("Not suggesting music source configuration")
      }
    }
    isFirstLoad = false
  }

  func computeMessage(_ folder: MusicFolder) -> String? {
    let isEmpty = folder.items.isEmpty
    if let selected = selected {
      return isEmpty ? "No tracks in folder \(selected.title)." : nil
    } else {
      // selected == nil means we are in the root library folder
      if isEmpty {
        if library.isLocal {
          return
            "The music library is empty. To get started, download and install the MusicPimp server from www.musicpimp.org, then add it as a music source under Settings."
        } else {
          return "The music library is empty."
        }
      } else {
        return nil
      }
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let item = musicItems[indexPath.row]
    let isFolder = item as? Folder != nil
    if isFolder {
      if let cell: DisclosureCell = findCell(folderCellId, index: indexPath) {
        cell.title.text = item.title
        cell.accessoryDelegate = self
        return cell
      }
      return super.tableView(tableView, cellForRowAt: indexPath)
    } else {
      if let track = item as? Track, let pimpCell = trackCell(track, index: indexPath) {
        paintTrackCell(
          cell: pimpCell, track: track, isHighlight: self.player.current().track?.id == track.id,
          downloadState: DownloadUpdater.instance.progressFor(track: track))
        return pimpCell
      } else {
        log.error("Invalid code path")
        // we should never get here
        return super.tableView(tableView, cellForRowAt: indexPath)
      }
    }
  }

  // When this method is defined, cells become swipeable
  override func tableView(
    _ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath
  ) {
  }

  override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath)
    -> [UITableViewRowAction]?
  {
    let playAction = musicItemAction(
      tableView,
      title: "Play",
      onTrack: { (t) -> Void in _ = await self.playTrack(t) },
      onFolder: { (f) -> Void in await self.playFolder(f.id) }
    )
    let addAction = musicItemAction(
      tableView,
      title: "Add",
      onTrack: { (t) -> Void in _ = await self.addTrack(t) },
      onFolder: { (f) -> Void in await self.addFolder(f.id) }
    )
    return [playAction, addAction]
  }

  func musicItemAction(
    _ tableView: UITableView, title: String, onTrack: @escaping (Track) async -> Void,
    onFolder: @escaping (Folder) async -> Void
  ) -> UITableViewRowAction {
    UITableViewRowAction(style: .default, title: title) {
      (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
      if let tappedItem = self.itemAt(tableView, indexPath: indexPath) {
        Task {
          if let track = tappedItem as? Track {
            await onTrack(track)
          }
          if let folder = tappedItem as? Folder {
            await onFolder(folder)
          }
        }
      }
      tableView.setEditing(false, animated: true)
    }
  }

  // Used when the user clicks a music item
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let item = itemAt(tableView, indexPath: indexPath) {
      if let folder = item as? Folder {
        let destination = LibraryContainer(folder: folder)
        navigationController?.pushViewController(destination, animated: true)
      }
      if let track = item as? Track {
        Task {
          _ = await playAndDownloadCheckedSingle(track)
        }
      }
    }
    tableView.deselectRow(at: indexPath, animated: false)
  }
}

extension LibraryController {
  func onProgress(track: TrackProgress) {
    if let index = musicItems.indexOf({ (item: MusicItem) -> Bool in
      item.idStr.description == track.track.idStr.description
    }) {
      log.info("Updating \(track.progress)")
      updateRows(row: index, p: track)
    }
  }

  private func updateRows(row: Int, p: TrackProgress) {
    let itemIndexPath = IndexPath(row: row, section: 0)
    self.tableView.reloadRows(at: [itemIndexPath], with: .none)
  }
}
