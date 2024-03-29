import Foundation

class BaseMusicController: PimpTableController, AccessoryDelegate {
  private let log = LoggerFactory.shared.vc(BaseMusicController.self)
  let folderCellId = "FolderCell"
  let trackCellId = "TrackCell"
  let defaultCellHeight: CGFloat = 44
  static let accessoryRightPadding: CGFloat = 14

  var musicItems: [MusicItem] { [] }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView?.register(SnapTrackCell.self, forCellReuseIdentifier: trackCellId)
    self.tableView?.register(DisclosureCell.self, forCellReuseIdentifier: folderCellId)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    currentFeedback == nil ? musicItems.count : 0
  }

  func trackCell(_ item: Track, index: IndexPath) -> SnapTrackCell? {
    if let pimpCell: SnapTrackCell = findCell(trackCellId, index: index) {
      pimpCell.title.text = item.title
      pimpCell.accessoryDelegate = self
      return pimpCell
    } else {
      log.error("Unable to find track cell for track \(item.title)")
      return nil
    }
  }

  func paintTrackCell(
    cell: SnapTrackCell, track: Track, isHighlight: Bool, downloadState: TrackProgress?
  ) {
    if let downloadProgress = downloadState {
      if cell.progress.progress < downloadProgress.progress {
        //                log.info("From \(cell.progress.progress) to \(downloadProgress.progress)")
        cell.progress.progress = downloadProgress.progress
      }
      if cell.progress.isHidden {
        cell.progress.isHidden = false
      }
    } else {
      cell.progress.isHidden = true
    }
    let (titleColor, selectionStyle) =
      isHighlight
      ? (PimpColors.shared.tintColor, UITableViewCell.SelectionStyle.blue)
      : (PimpColors.shared.titles, UITableViewCell.SelectionStyle.default)
    cell.title.textColor = titleColor
    cell.selectionStyle = selectionStyle
  }

  func accessoryTapped(_ sender: UIButton, event: AnyObject) {
    if let row = clickedRow(event) {
      let item = musicItems[row]
      if let track = item as? Track {
        displayActionsForTrack(track, row: row, sender: sender)
      }
      if let folder = item as? Folder {
        displayActionsForFolder(folder, row: row)
      }
    } else {
      log.error("Unable to determine touched row")
    }
  }

  func displayActionsForTrack(_ track: Track, row: Int, sender: UIButton) {
    let title = track.title
    let message = track.artist
    let sheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
    sheet.view.window?.backgroundColor = PimpColors.shared.background
    let playAction = playTrackAccessoryAction(track, row: row)
    let addAction = addTrackAccessoryAction(track, row: row)
    let downloadAction = accessoryAction("Download") { _ in
      _ = self.downloadIfNeeded([track])
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
    }
    sheet.addAction(playAction)
    sheet.addAction(addAction)
    if !LocalLibrary.sharedInstance.contains(track) {
      sheet.addAction(downloadAction)
    }
    sheet.addAction(cancelAction)
    // For iPad: Positions the action sheet next to the tapped element, in this case the accessory view
    if let popover = sheet.popoverPresentationController {
      popover.sourceView = sender
    }
    self.present(sheet, animated: true, completion: nil)
  }

  func playTrackAccessoryAction(_ track: Track, row: Int) -> UIAlertAction {
    accessoryAction("Play", action: { _ in _ = Task { await self.playTrack(track) } })
  }

  func addTrackAccessoryAction(_ track: Track, row: Int) -> UIAlertAction {
    accessoryAction("Add", action: { _ in _ = Task { await self.addTrack(track) } })
  }

  func displayActionsForFolder(_ folder: Folder, row: Int) {
    let destination = LibraryContainer(folder: folder)
    navigationController?.pushViewController(destination, animated: true)
  }

  func displayActionsForFolder2(_ folder: Folder, row: Int) {
    log.info("Display for folder " + folder.title)
    let title = folder.title
    let id = folder.id
    let message = ""
    let sheet = UIAlertController(
      title: title, message: message, preferredStyle: UIAlertController.Style.actionSheet)
    let playAction = accessoryAction("Play", action: { _ in await self.playFolder(id) })
    let addAction = accessoryAction("Add", action: { _ in await self.addFolder(id) })
    let downloadAction = accessoryAction("Download") { _ in
      Task {
        await self.withTracks(id: id, f: self.downloadIfNeeded)
      }
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { _ in

    }
    sheet.addAction(playAction)
    sheet.addAction(addAction)
    if !self.library.isLocal {
      sheet.addAction(downloadAction)
    }
    sheet.addAction(cancelAction)
    self.present(sheet, animated: true, completion: nil)
  }

  func accessoryAction(_ title: String, action: @escaping (UIAlertAction) async -> Void)
    -> UIAlertAction
  {
    UIAlertAction(title: title, style: UIAlertAction.Style.default) { uiaa in
      Task {
        await action(uiaa)
      }
    }
  }

  func playFolder(_ id: FolderID) async {
    await withTracks(id: id, f: self.playTracksChecked)
  }

  func playTrack(_ track: Track) async -> ErrorMessage? {
    await playTracksChecked([track]).headOption()
  }

  func addFolder(_ id: FolderID) async {
    await withTracks(id: id, f: self.addTracksChecked)
  }

  func withTracks(id: FolderID, f: @escaping ([Track]) async -> [ErrorMessage]) async {
    do {
      let ts = try await library.tracks(id)
      let _ = await f(ts)
    } catch {
      onError(error)
    }
  }

  func addTrack(_ track: Track) async -> ErrorMessage? {
    await addTracksChecked([track]).headOption()
  }

  func reload(_ emptyText: String) {
    withReload(emptyText) {}
  }

  func withReload(_ emptyText: String, _ code: @escaping () -> Void) {
    onUiThread {
      code()
      self.reloadTable(feedback: self.musicItems.count == 0 ? emptyText : nil)
    }
  }

  func withMessage(_ message: String?, _ code: @escaping () -> Void) {
    onUiThread {
      code()
      self.reloadTable(feedback: message)
    }
  }
}
