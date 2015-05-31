//
//  LibraryController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class LibraryController: PimpTableController {
    static let LIBRARY = "library", PLAYER = "player"
    
    var musicItems: [MusicItem] = []
    var selected: MusicItem? = nil
    
    private var socket: PimpSocket? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        if let folderID = selected?.id {
            loadFolder(folderID)
        } else {
            loadRoot()
        }
        LibraryManager.sharedInstance.libraryChanged.addHandler(self, handler: { (ivc) -> LibraryType -> () in
            ivc.onLibraryChanged
        })
    }
    func onLibraryChanged(e: LibraryType) {
        if let navController = navigationController {
            navController.popToRootViewControllerAnimated(false)
            loadRoot()
        }
    }
    func loadFolder(id: String) {
        library.folder(id, onError: onError, f: onFolder)
    }
    func loadRoot() {
        library.rootFolder(onError, f: onFolder)
    }
    func onFolder(f: MusicFolder) {
        //info("Loaded \(f.folder.title) with \(f.tracks.count) tracks")
        let fs: [MusicItem] = f.folders
        let ts: [MusicItem] = f.tracks
        let items: [MusicItem] = fs + ts
        musicItems = items
        renderTable()
    }
    func onError(error: PimpError) {
        info(PimpErrorUtil.stringify(error))
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.musicItems.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = musicItems[indexPath.row]
        let (prototypeID, accessoryType) = (item as? Folder != nil) ? ("FolderCell", UITableViewCellAccessoryType.DisclosureIndicator) : ("TrackCell", UITableViewCellAccessoryType.None)
        let cell = tableView.dequeueReusableCellWithIdentifier(prototypeID, forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = item.title
        cell.accessoryType = accessoryType
        return cell
    }
    // When this method is defined, cells become swipeable
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var addAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Add") {
            (action:UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let tappedItem: MusicItem = self.musicItems[indexPath.row]
            if let track = tappedItem as? Track {
                self.addTracks([track])
            }
            if let folder = tappedItem as? Folder {
                self.addFolder(folder.id)
            }
        }
        return [addAction]
    }
    func addFolder(id: String) {
        library.tracks(id, onError: onError, f: addTracks)
    }
    func addTracks(tracks: [Track]) {
        player.playlist.add(tracks)
        if(!library.isLocal) {
            for track in tracks.take(10) {
                startDownload(track)
            }
        }
    }
    // Used when the user clicks a track or otherwise modifies the player
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let tappedItem: MusicItem = musicItems[indexPath.row]
        if let track = tappedItem as? Track {
            player.resetAndPlay(track)
            if(!library.isLocal) {
                startDownload(track)
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    private func startDownload(track: Track) {
        Downloader.musicDownloader.download(track.url, relativePath: track.path)
    }
    // Performs segue if the user clicked a folder
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == LibraryController.LIBRARY {
            if let row = self.tableView.indexPathForSelectedRow() {
                var index = row.item
                return musicItems.count > index && musicItems[index] is Folder
            } else {
                info("Cannot navigate to item at row \(index)")
                return false
            }
        }
        info("Unknown identifier: \(identifier)")
        return false
    }
    
    // Used when the user taps a folder, initiating a navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let navController = segue.destinationViewController as? UINavigationController {
            let destController: AnyObject = navController.viewControllers[0]
            if let itemsController = destController as? LibraryController {
                var row = self.tableView.indexPathForSelectedRow()!
                var item = musicItems[row.item]
                itemsController.selected = item
            } else if let playerController = destController as? PlayerController {
                //info("Unknown destination controller")
            } else {
                
            }
        } else {
            Log.info("Unknown navigation controller")
        }
    }
    
    @IBAction func unwindToItems(segue: UIStoryboardSegue) {
        Log.info("Unwinding")
        if let id = (segue.sourceViewController as? LibraryController)?.selected?.id {
            loadFolder(id)
        } else {
            loadRoot()
        }
        if let previous = segue.sourceViewController as? LibraryController {
            let title = previous.selected?.title
        }
    }
}
