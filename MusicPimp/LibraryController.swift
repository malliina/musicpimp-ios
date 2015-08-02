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
    static let TABLE_CELL_HEIGHT_PLAIN = 44
    
    static var libraryListener: Disposable? = nil
    static var contentListener: Disposable? = nil
    
    var musicItems: [MusicItem] = []
    var selected: MusicItem? = nil
    
    var header: UIView? = nil
    var feedback: UILabel? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityView.frame = CGRect(x: 0, y: 0, width: 320, height: LibraryController.TABLE_CELL_HEIGHT_PLAIN)
        activityView.startAnimating()
        self.tableView.tableHeaderView = activityView
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        let feedbackLabel = UILabel(frame: CGRect(x: 16, y: 0, width: 300, height: 44))
        feedbackLabel.textColor = UIColor.blueColor()
        headerView.addSubview(feedbackLabel)
        self.feedback = feedbackLabel
        self.header = headerView
        
        if let folderID = selected?.id {
            loadFolder(folderID)
        } else {
            loadRoot()
        }
    }
    @IBAction func refreshClicked(sender: UIBarButtonItem) {
        info("Refresh from \(self)")
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    private func resetLibrary() {
        loadRoot()
    }
    // Calls popToRootViewControllerAnimated on the deepest UINavigationController
    private func popAll(ctrl: UIViewController) -> [AnyObject] {
        let stack = navStack(ctrl, acc: [])
        let dfs = stack.reverse()
        var popped: [AnyObject] = []
        for nav in dfs {
            info("Popping \(nav)")
            popped = popped + (nav.popToRootViewControllerAnimated(false) ?? [])
        }
        return popped
    }
    private func deepestNavController(ctrl: UIViewController) -> UINavigationController? {
        if let parent = ctrl.parentViewController {
            return deepestNavController(parent) ?? parent.navigationController
        } else {
            return nil
        }
    }
    private func navStack(ctrl: UIViewController, acc: [UINavigationController]) -> [UINavigationController] {
        if let parent = ctrl.parentViewController {
            if let nav = parent.navigationController {
                let newAcc = acc + [nav]
                return navStack(parent, acc: newAcc)
            } else {
                return acc
            }
        } else {
            return acc
        }
 
    }
    func loadFolder(id: String) {
        library.folder(id, onError: onError, f: onFolder)
    }
    func loadRoot() {
        info("Loading \(library)")
        library.rootFolder(onError, f: onFolder)
    }
    func onFolder(f: MusicFolder) {
        //info("Loaded \(f.folder.title) with \(f.tracks.count) tracks")
        let fs: [MusicItem] = f.folders
        let ts: [MusicItem] = f.tracks
        let items: [MusicItem] = fs + ts
        musicItems = items
        Util.onUiThread({ () in
            self.tableView.tableHeaderView = nil
            self.tableView.reloadData()
        })
    }
    func onError(error: PimpError) {
        let message = PimpErrorUtil.stringify(error)
        Util.onUiThread({
            () in
            self.feedback?.text = message
            self.tableView.tableHeaderView = nil
            if let header = self.header {
                self.tableView.tableHeaderView = header
            }
        })
        info(message)
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
        let playAction = musicItemAction(
            tableView,
            title: "Play",
            onTrack: { (t) -> Void in self.playTracks([t]) },
            onFolder: { (f) -> Void in self.playFolder(f.id) }
        )
        let addAction = musicItemAction(
            tableView,
            title: "Add",
            onTrack: { (t) -> Void in self.addTracks([t]) },
            onFolder: { (f) -> Void in self.addFolder(f.id) }
        )
        return [playAction, addAction]
    }
    func musicItemAction(tableView: UITableView, title: String, onTrack: Track -> Void, onFolder: Folder -> Void) -> UITableViewRowAction {
        return UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title) {
            (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let tappedItem: MusicItem = self.musicItems[indexPath.row]
            if let track = tappedItem as? Track {
                onTrack(track)
            }
            if let folder = tappedItem as? Folder {
                onFolder(folder)
            }
            tableView.setEditing(false, animated: true)
        }
    }
    func playFolder(id: String) {
        library.tracks(id, onError: onError, f: playTracks)
    }
    func playTracks(tracks: [Track]) {
        if let first = tracks.first {
            playAndDownload(first)
            addTracks(tracks.tail())
        }
    }
    func addFolder(id: String) {
        info("Adding folder")
        library.tracks(id, onError: onError, f: addTracks)
    }
    func addTracks(tracks: [Track]) {
        info("Adding \(tracks.count) tracks")
        player.playlist.add(tracks)
        downloadIfNeeded(tracks)
    }
    // Used when the user clicks a track or otherwise modifies the player
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let cell = tableView.cellForRowAtIndexPath(indexPath)
        let tappedItem: MusicItem = musicItems[indexPath.row]
        if let track = tappedItem as? Track {
            playAndDownload(track)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    private func playAndDownload(track: Track) {
        player.resetAndPlay(track)
        downloadIfNeeded([track])
    }
    private func downloadIfNeeded(tracks: [Track]) {
        if !library.isLocal && player.isLocal && settings.cacheEnabled {
            let newTracks = tracks.filter({ !LocalLibrary.sharedInstance.contains($0) })
            for track in newTracks.take(10) {
                startDownload(track)
            }
        }
    }
    private func startDownload(track: Track) {
        Downloader.musicDownloader.download(track.url, relativePath: track.path, replace: true)
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
        info("prepareForSegue")
        if let destination = segue.destinationViewController as? LibraryController {
            if let row = self.tableView.indexPathForSelectedRow() {
                destination.selected = musicItems[row.item]
            }
        } else {
            error("Unknown destination controller")
        }
    }
    
    @IBAction func unwindToItems(segue: UIStoryboardSegue) {
        info("unwindToItems")
        let src = segue.sourceViewController as? LibraryController
        if let id = src?.selected?.id {
            loadFolder(id)
        } else {
            loadRoot()
        }
    }
}
