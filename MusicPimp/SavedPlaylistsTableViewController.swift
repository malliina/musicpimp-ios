//
//  SavedPlaylistsTableViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

protocol PlaylistSelectDelegate {
    func playlistActivated(_ playlist: SavedPlaylist)
}

class SavedPlaylistsTableViewController: PimpTableController {
    let emptyMessage = "No saved playlists."
    let loadingMessage = "Loading playlists..."
    let playlistCell = "PlaylistCell"
    
    var playlists: [SavedPlaylist] = []
    var delegate: PlaylistSelectDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "SELECT TO PLAY"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.goBack))
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: playlistCell)
        loadPlaylists()
    }
    
    func loadPlaylists() {
        setFeedback(loadingMessage)
        library.playlists(onLoadError, f: onPlaylists)
    }
    
    func onPlaylists(_ sps: [SavedPlaylist]) {
        playlists = sps
        let feedback: String? = sps.isEmpty ? emptyMessage : nil
        renderTable(feedback)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = playlists[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: playlistCell, for: indexPath)
        cell.textLabel?.text = item.name
        // Why doesn't AppDelegate.initTheme settings apply here?
        cell.textLabel?.textColor = PimpColors.titles
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        if playlists.count > 0 && playlists.count > row {
            let item = playlists[row]
            _ = playTracks(item.tracks)
            delegate?.playlistActivated(item)
        }
        tableView.deselectRow(at: indexPath, animated: false)
        goBack()
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let playlist = playlists[index]
        if let id = playlist.id {
            library.deletePlaylist(id, onError: onError) {
                Log.info("Deleted playlist with ID \(id)")
                self.playlists.remove(at: index)
                self.renderTable()
            }
        }
    }
    
    func goBack() {
        dismiss(animated: true, completion: nil)
    }
}
