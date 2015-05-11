//
//  PlaylistController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class PlaylistController: UITableViewController {
    let player = LocalPlayer.sharedInstance
    
    var current: Playlist = Playlist.empty
    var tracks: [Track] { get { return current.tracks } }
    var selected: MusicItem? = nil
    var listeners: [Disposable] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(animated: Bool) {
        let playlistDisposable = player.playlist.playlistEvent.addHandler(self, handler: { (plc: PlaylistController) -> Playlist -> () in
            plc.onNewPlaylist
        })
        let indexDisposable = player.playlist.indexEvent.addHandler(self, handler: { (plc: PlaylistController) -> Int? -> () in
            plc.onIndexChanged
        })
        listeners = [playlistDisposable, indexDisposable]
        current = player.playlist.current()
        renderTable()
    }
    override func viewWillDisappear(animated: Bool) {
        for listener in listeners {
            listener.dispose()
        }
        listeners = []
    }
    func onNewPlaylist(playlist: Playlist) {
        self.current = playlist
        renderTable()
    }
    func onIndexChanged(index: Int?) {
        self.current = Playlist(tracks: current.tracks, index: index)
        renderTable()
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let index = indexPath.row
        let item = tracks[index]
        let prototypeID = index == current.index ? "CurrentPlaylistItem" : "PlaylistItem"
        let cell = tableView.dequeueReusableCellWithIdentifier(prototypeID, forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = item.title
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let index = indexPath.row
        let tappedItem: MusicItem = tracks[index]
        if let track = tappedItem as? Track {
            player.skip(index)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let index = indexPath.row
//        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        player.playlist.removeIndex(index)
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func renderTable() {
        Util.onUiThread({ () in self.tableView.reloadData()})
    }
    func info(s: String){
        Log.info(s)
    }
}