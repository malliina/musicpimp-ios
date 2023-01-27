import Foundation

class PlaylistContentsTable: BaseTableController {
    let identifier = PlaylistTrackCell.identifier
    let playlist: SavedPlaylist
    var tracks: [Track] { playlist.tracks }
    
    init(playlist: SavedPlaylist) {
        self.playlist = playlist
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(PlaylistTrackCell.self, forCellReuseIdentifier: identifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PlaylistTrackCell = loadCell(identifier, index: indexPath)
        let track = tracks[indexPath.row]
        cell.fill(main: track.title, subLeft: track.artist, subRight: track.duration.description)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tracks.count
    }
}
