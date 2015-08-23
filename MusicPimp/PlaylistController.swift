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
    var current: Playlist = Playlist.empty
    var tracks: [Track] { get { return current.tracks } }
    var selected: MusicItem? = nil
    var listeners: [Disposable] = []
    private var downloadState: [Track: TrackProgress] = [:]

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
    func onNewPlaylist(playlist: Playlist) {
        self.current = playlist
//        info("New playlist with \(tracks.count) tracks")
        renderTable()
    }
    func onIndexChanged(index: Int?) {
        self.current = Playlist(tracks: current.tracks, index: index)
        renderTable()
    }
    func onDownloadProgressUpdate(dpu: DownloadProgressUpdate) {
        if let track = tracks.find({ (t: Track) -> Bool in t.path == dpu.relativePath }),
            index = tracks.indexOf({ (item: MusicItem) -> Bool in item.id == track.id }) {
                let isDownloadComplete = track.size == dpu.written
                if isDownloadComplete {
                    downloadState.removeValueForKey(track)
                } else {
                    downloadState[track] = TrackProgress(track: track, dpu: dpu)
                }
                let itemIndexPath = NSIndexPath(forRow: index, inSection: 0)
                
                Util.onUiThread({
                    self.tableView.reloadRowsAtIndexPaths([itemIndexPath], withRowAnimation: UITableViewRowAnimation.None)
                })
        }
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
        cell.textLabel?.text = track.title
        if isCurrent {
            cell.textLabel?.textColor = UIColor.blueColor()
            cell.selectionStyle = UITableViewCellSelectionStyle.Blue
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyle.Default
        }
        return cell
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
//        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        player.playlist.removeIndex(index)
//        tracks = current.tracks
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
}