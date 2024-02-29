import Foundation

protocol PlaylistSelectDelegate {
  func playlistActivated(_ playlist: SavedPlaylist)
}

class SavedPlaylistsTableViewController: PimpTableController {
  let log = LoggerFactory.shared.vc(SavedPlaylistsTableViewController.self)
  let emptyMessage = "No saved playlists."
  let loadingMessage = "Loading playlists..."
  let playlistCell = "PlaylistCell"

  var playlists: [SavedPlaylist] = []
  var delegate: PlaylistSelectDelegate? = nil

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "SELECT TO PLAY"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .done, target: self, action: #selector(self.goBack))
    self.tableView.register(SavedPlaylistCell.self, forCellReuseIdentifier: playlistCell)
    Task {
      await loadPlaylists()
    }
  }

  @MainActor
  func loadPlaylists() async {
    setFeedback(loadingMessage)
    do {
      let ps = try await library.playlists()
      onPlaylists(ps)
    } catch {
      onLoadError(error)
    }
  }

  func onPlaylists(_ sps: [SavedPlaylist]) {
    onUiThread {
      self.playlists = sps
      let feedback: String? = sps.isEmpty ? self.emptyMessage : nil
      self.reloadTable(feedback: feedback)
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    playlists.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let item = playlists[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: playlistCell, for: indexPath)
    if let cell = cell as? SavedPlaylistCell {
      cell.fill(
        main: item.name, subLeft: "\(item.trackCount) tracks",
        subRight: "\(item.duration.description)")
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = indexPath.row
    if playlists.count > 0 && playlists.count > row {
      let item = playlists[row]
      _ = playTracksChecked(item.tracks)
      delegate?.playlistActivated(item)
    }
    tableView.deselectRow(at: indexPath, animated: false)
    goBack()
  }

  override func tableView(
    _ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath
  ) {
    let index = indexPath.row
    let playlist = playlists[index]
    if let id = playlist.id {
      Task {
        do {
          let _ = try await library.deletePlaylist(id)
          log.info("Deleted playlist with ID \(id)")
          rem(at: index)
        } catch {
          onError(error)
        }
      }
    }
  }
  
  @MainActor
  private func rem(at: Int) {
    playlists.remove(at: at)
    reloadTable(feedback: nil)
  }

  override func tableView(
    _ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath
  ) {
    log.info("Tapped")
  }
}
