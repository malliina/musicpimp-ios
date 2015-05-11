//
//  ItemsViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class ItemsViewController: MusicItemsController {
    static let LIBRARY = "library", PLAYER = "player"
    let client = PimpHttpClient(baseURL: "http://localhost:8456", username: "mle", password: "mac")
    
    var musicItems: [MusicItem] = []
    var selected: MusicItem? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let folderId = selected?.id ?? "root"
//        Log.info("Loading: \(folderId)")
        if let folderID = selected?.id {
            loadFolder(folderID)
        } else {
            loadRoot()
        }
    }
    func loadFolder(id: String) {
        client.folder(id, f: onFolder)
    }
    func loadRoot() {
        client.rootFolder(onFolder)
    }
    func onFolder(f: MusicFolder) {
        let fs: [MusicItem] = f.folders
        let ts: [MusicItem] = f.tracks
        let items: [MusicItem] = fs + ts
        musicItems = items
        renderTable()
    }
    func renderTable() {
       Util.onUiThread({ () in self.tableView.reloadData()})
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
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
        client.tracks(id, f: addTracks)
    }
    func addTracks(tracks: [Track]) {
        LocalPlayer.sharedInstance.playlist.add(tracks)
    }
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.Right:
                println("Swiped right")
            case UISwipeGestureRecognizerDirection.Down:
                println("Swiped down")
            default:
                break
            }
        }    }
    
    // Used when the user clicks a track or otherwise modifies the player
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let tappedItem: MusicItem = musicItems[indexPath.row]
        if let track = tappedItem as? Track {
            LocalPlayer.sharedInstance.resetAndPlay(track)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    // Performs segue if the user clicked a folder
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == ItemsViewController.LIBRARY {
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
            if let itemsController = destController as? ItemsViewController {
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
        if let id = (segue.sourceViewController as? ItemsViewController)?.selected?.id {
            loadFolder(id)
        } else {
            loadRoot()
        }
        if let previous = segue.sourceViewController as? ItemsViewController {
            let title = previous.selected?.title
        }
    }
    
}