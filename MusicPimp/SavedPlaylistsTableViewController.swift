//
//  SavedPlaylistsTableViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class SavedPlaylistsTableViewController: PimpTableController {
    
    var playlists: [SavedPlaylist] = []
    
    @IBAction func doneButton(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: PimpTableController.feedbackIdentifier)
        feedbackMessage = "Loading playlists..."
        loadPlaylists()
    }
    
    func loadPlaylists() {
        library.playlists(onLoadError, f: onPlaylists)
    }
    
    func onPlaylists(sps: [SavedPlaylist]) {
        feedbackMessage = nil
        playlists = sps
        renderTable()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Max one because we display feedback to the user if the table is empty
        return max(playlists.count, 1)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if playlists.count == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(BaseMusicController.feedbackIdentifier, forIndexPath: indexPath)
            let statusMessage = feedbackMessage ?? "No saved playlists"
            cell.textLabel?.text = statusMessage
            return cell
        } else {
            let item = playlists[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("PlaylistCell", forIndexPath: indexPath)
            cell.textLabel?.text = item.name
            return cell
        }
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
