//
//  PlaylistController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class PlaylistController: PimpTableController {
    let emptyMessage = "The playlist is empty."
    var current: Playlist = Playlist.empty
    var tracks: [Track] { get { return current.tracks } }
    var selected: MusicItem? = nil
    // non-nil if the playlist is server-loaded
    var savedPlaylist: SavedPlaylist? = nil
    var listeners: [Disposable] = []
    private var downloadState: [Track: TrackProgress] = [:]

    @IBOutlet var dragButton: UIBarButtonItem!
    
    @IBAction func dragClicked(sender: UIBarButtonItem) {
        let isEditing = self.tableView.editing
        self.tableView.setEditing(!isEditing, animated: true)
        let title = isEditing ? "Edit" : "Done"
        dragButton.style = isEditing ? UIBarButtonItemStyle.Plain : UIBarButtonItemStyle.Done
        dragButton.title = title
    }
    
    override func viewDidLoad() {
        let saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "savePlaylistAction")
        saveButton.style = UIBarButtonItemStyle.Done
        // the first element in the array is right-most
        self.navigationItem.rightBarButtonItems = [ saveButton ]
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        downloadState = [:]
        let playlistDisposable = player.playlist.playlistEvent.addHandler(self, handler: { (plc: PlaylistController) -> Playlist -> () in
            plc.onNewPlaylist
        })
        let indexDisposable = player.playlist.indexEvent.addHandler(self, handler: { (plc: PlaylistController) -> Int? -> () in
            plc.onIndexChanged
        })
        let downloadProgressDisposable = BackgroundDownloader.musicDownloader.events.addHandler(self, handler: { (plc) -> DownloadProgressUpdate -> () in
            plc.onDownloadProgressUpdate
        })
        listeners = [playlistDisposable, indexDisposable, downloadProgressDisposable]
        let state = player.current()
        let currentPlaylist = Playlist(tracks: state.playlist, index: state.playlistIndex)
        onNewPlaylist(currentPlaylist)
    }
    
    override func viewWillDisappear(animated: Bool) {
        for listener in listeners {
            listener.dispose()
        }
        listeners = []
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        if tracks.count == 0 {
//            tableView.backgroundView = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
//            return feedbackCellWithText(tableView, indexPath: indexPath, text: feedbackMessage ?? "The playlist is empty")
//        } else {
            let index = indexPath.row
            let track = tracks[index]
            let isCurrent = index == current.index
            let arr = NSBundle.mainBundle().loadNibNamed("PimpMusicItemCell", owner: self, options: nil)
            let cell = arr[0] as! PimpMusicItemCell
            if let downloadProgress = downloadState[track] {
                //info("Setting progress to \(downloadProgress.progress)")
                cell.progressView.progress = downloadProgress.progress
                cell.progressView.hidden = false
            } else {
                cell.progressView.hidden = true
            }
            cell.titleLabel?.text = track.title
            if isCurrent {
                cell.titleLabel?.textColor = UIColor.blueColor()
                cell.selectionStyle = UITableViewCellSelectionStyle.Blue
            } else {
                cell.selectionStyle = UITableViewCellSelectionStyle.Default
            }
            return cell

//        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let cell = tableView.cellForRowAtIndexPath(indexPath)
        let index = indexPath.row
        player.skip(index)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let index = indexPath.row
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        player.playlist.removeIndex(index)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Max one because we display feedback to the user if the table is empty
//        return max(self.tracks.count, 1)
        return self.tracks.count
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let sourceRow = sourceIndexPath.row
        let destinationRow = destinationIndexPath.row
        let newTracks = Arrays.move(sourceRow, destIndex: destinationRow, xs: current.tracks)
        let newIndex = computeNewIndex(sourceRow, dest: destinationRow)
        current = Playlist(tracks: newTracks, index: newIndex)
        player.playlist.move(sourceRow, dest: destinationRow)
    }
    
    func computeNewIndex(src: Int, dest: Int) -> Int? {
        if let index = current.index {
            return LocalPlaylist.newPlaylistIndex(index, src: src, dest: dest)
        }
        return nil
    }
    
    func savePlaylistAction() {
        if let playlist = savedPlaylist {
            // opens actions drop-up: does the user want to save the existing playlist or create a new one?
            displayActionsForPlaylist(playlist)
        } else {
            // goes directly to the "new playlist" view controller
            newPlaylistAction()
        }
    }
    
    func displayActionsForPlaylist(playlist: SavedPlaylist) {
        let title = "Save Playlist"
        let message = playlist.name
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let saveAction = UIAlertAction(title: "Save Current", style: UIAlertActionStyle.Default) { (a) -> Void in
            self.savePlaylist(playlist)
        }
        let newAction = UIAlertAction(title: "Create New", style: UIAlertActionStyle.Default) { (a) -> Void in
            self.newPlaylistAction()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (a) -> Void in
            
        }
        sheet.addAction(saveAction)
        sheet.addAction(newAction)
        sheet.addAction(cancelAction)
        self.presentViewController(sheet, animated: true, completion: nil)
    }
    
    func newPlaylistAction() {
        if let storyboard = self.storyboard {
            let vc = storyboard.instantiateViewControllerWithIdentifier("SavePlaylist")
            vc.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
            if let spvc = vc as? SavePlaylistViewController, playlist = savedPlaylist {
                spvc.name = playlist.name
            }
//            self.navigationController?.pushViewController(vc, animated: true)
            let navController = UINavigationController(rootViewController: vc)
            self.presentViewController(navController, animated: true, completion: nil)
        } else {
            Log.error("No storyboard, cannot open save playlist ViewController")
        }
    }

    func onNewPlaylist(playlist: Playlist) {
        self.current = playlist
        renderTable(self.tracks.count == 0 ? self.emptyMessage : nil)
    }
    
    func onIndexChanged(index: Int?) {
        self.current = Playlist(tracks: current.tracks, index: index)
        renderTable()
    }
    
    func onDownloadProgressUpdate(dpu: DownloadProgressUpdate) {
        //info("Written \(dpu.written) of \(dpu.relativePath)")
        if let track = tracks.find({ (t: Track) -> Bool in t.path == dpu.relativePath }),
            index = tracks.indexOf({ (item: Track) -> Bool in item.path == track.path }) {
            let isDownloadComplete = track.size == dpu.written
            if isDownloadComplete {
                downloadState.removeValueForKey(track)
            } else {
                downloadState[track] = TrackProgress(track: track, dpu: dpu)
            }
            let itemIndexPath = NSIndexPath(forRow: index, inSection: 0)
            
            Util.onUiThread {
                // The app crashed if reloading a row while concurrently dragging and dropping rows.
                // TODO investigate and fix, but as a workaround, we don't update the download progress when editing.
                if !self.tableView.editing {
                    self.tableView.reloadRowsAtIndexPaths([itemIndexPath], withRowAnimation: UITableViewRowAnimation.None)
                }
            }
        }
    }
    
    @IBAction func unwindToPlaylist(sender: UIStoryboardSegue) {
        // returns from a "new playlist" screen
        if let source = sender.sourceViewController as? SavePlaylistViewController, name = source.name {
            let playlist = SavedPlaylist(id: nil, name: name, tracks: self.tracks)
            savePlaylist(playlist)
        }
    }
    
    private func savePlaylist(playlist: SavedPlaylist) {
        library.savePlaylist(playlist, onError: onError) { (id: PlaylistID) -> Void in
            self.savedPlaylist = SavedPlaylist(id: id, name: playlist.name, tracks: playlist.tracks)
            Log.info("Saved playlist with name \(playlist.name) and ID \(id.id)")
        }
    }
}
