//
//  SavedPlaylistsTableViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class SavedPlaylistsTableViewController: PimpTableController {
    let emptyMessage = "No saved playlists."
    let loadingMessage = "Loading playlists..."
    let playlistCell = "PlaylistCell"
    
    var playlists: [SavedPlaylist] = []
    
    @IBAction func doneButton(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Select to Play"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(self.goBack))
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: playlistCell)
        loadPlaylists()
    }
    
    func loadPlaylists() {
        setFeedback(loadingMessage)
        library.playlists(onLoadError, f: onPlaylists)
    }
    
    func onPlaylists(sps: [SavedPlaylist]) {
        playlists = sps
        let feedback: String? = sps.isEmpty ? "No saved playlists" : nil
        renderTable(feedback)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = playlists[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(playlistCell, forIndexPath: indexPath)
        cell.textLabel?.text = item.name
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        if playlists.count > 0 && playlists.count > row {
            let item = playlists[row]
            playTracks(item.tracks)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        goBack()
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let index = indexPath.row
        let playlist = playlists[index]
        if let id = playlist.id {
            library.deletePlaylist(id, onError: onError) {
                Log.info("Deleted playlist with ID \(id)")
                self.playlists.removeAtIndex(index)
                self.renderTable()
            }
        }
    }
    
    func goBack() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
