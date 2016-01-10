//
//  LibraryController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class LibraryController: SearchableMusicController {
    static let LIBRARY = "library", PLAYER = "player"
    // TODO articulate these magic numbers
    static let TABLE_CELL_HEIGHT_PLAIN = 44
    let halfCellHeight = LibraryController.TABLE_CELL_HEIGHT_PLAIN / 2
    
    var folder: MusicFolder = MusicFolder.empty
    override var musicItems: [MusicItem] { return folder.items }
    var selected: MusicItem? = nil
    
    var header: UIView? = nil
    
    private var downloadUpdates: Disposable? = nil
    private var downloadState: [Track: TrackProgress] = [:]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        feedbackMessage = "Loading..."
        if let folder = selected {
            self.navigationItem.title = folder.title
            loadFolder(folder.id)
        } else {
            loadRoot()
        }
    }
    
    @IBAction func refreshClicked(sender: UIBarButtonItem) {
        info("Item clicked")
    }
    
    private func resetLibrary() {
        loadRoot()
    }
    
    func loadFolder(id: String) {
        library.folder(id, onError: onLoadError, f: onFolder)
    }
    
    func loadRoot() {
        info("Loading \(library)")
        library.rootFolder(onLoadError, f: onFolder)
    }
    
    func onFolder(f: MusicFolder) {
        feedbackMessage = nil
        folder = f
        self.renderTable()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if musicItems.count == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(BaseMusicController.feedbackIdentifier, forIndexPath: indexPath)
            if let label = cell.textLabel {
                label.lineBreakMode = NSLineBreakMode.ByWordWrapping
                label.numberOfLines = 0
                let statusMessage = feedbackMessage ?? "No tracks"
                label.text = statusMessage
            }
            return cell
        } else {
            let item = musicItems[indexPath.row]
            let isFolder = item as? Folder != nil
            var cell: UITableViewCell? = nil
            if isFolder {
                let folderCell = tableView.dequeueReusableCellWithIdentifier("FolderCell", forIndexPath: indexPath)
                folderCell.textLabel?.text = item.title
                folderCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                cell = folderCell
            } else {
                if let track = item as? Track, pimpCell = trackCell(track) {
                    if let downloadProgress = downloadState[track] {
                        //info("Setting progress to \(downloadProgress.progress)")
                        pimpCell.progressView.progress = downloadProgress.progress
                        pimpCell.progressView.hidden = false
                    } else {
                        pimpCell.progressView.hidden = true
                    }
                    cell = pimpCell
                }
            }
            return cell!
        }
    }
    
    func sheetAction(title: String, item: MusicItem, onTrack: Track -> Void, onFolder: Folder -> Void) -> UIAlertAction {
        return UIAlertAction(title: title, style: UIAlertActionStyle.Default) { (a) -> Void in
            if let track = item as? Track {
                onTrack(track)
            }
            if let folder = item as? Folder {
                onFolder(folder)
            }
        }
    }
    
    // When this method is defined, cells become swipeable
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let playAction = musicItemAction(
            tableView,
            title: "Play",
            onTrack: { (t) -> Void in self.playTrack(t) },
            onFolder: { (f) -> Void in self.playFolder(f.id) }
        )
        let addAction = musicItemAction(
            tableView,
            title: "Add",
            onTrack: { (t) -> Void in self.addTrack(t) },
            onFolder: { (f) -> Void in self.addFolder(f.id) }
        )
        return [playAction, addAction]
    }
    
    func musicItemAction(tableView: UITableView, title: String, onTrack: Track -> Void, onFolder: Folder -> Void) -> UITableViewRowAction {
        return UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title) {
            (action: UITableViewRowAction, indexPath: NSIndexPath) -> Void in
            if let tappedItem = self.itemAt(tableView, indexPath: indexPath) {
                if let track = tappedItem as? Track {
                    onTrack(track)
                }
                if let folder = tappedItem as? Folder {
                    onFolder(folder)
                }
            }
            tableView.setEditing(false, animated: true)
        }
    }
    
    // Used when the user clicks a track or otherwise modifies the player
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let item = itemAt(tableView, indexPath: indexPath), track = item as? Track {
            playAndDownload(track)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    // Performs segue if the user clicked a folder
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == LibraryController.LIBRARY {
            if let row = self.tableView.indexPathForSelectedRow {
                let index = row.item
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
            if let row = self.tableView.indexPathForSelectedRow {
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

extension LibraryController {
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        downloadState = [:]
        downloadUpdates = BackgroundDownloader.musicDownloader.events.addHandler(self, handler: { (lc) -> DownloadProgressUpdate -> () in
            lc.onDownloadProgressUpdate
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if downloadState.isEmpty {
            disposeDownloadProgress()
        }
    }
    
    func disposeDownloadProgress() {
        downloadUpdates?.dispose()
        downloadUpdates = nil
    }
    
    func onDownloadProgressUpdate(dpu: DownloadProgressUpdate) {
        let tracks = folder.tracks
        if let track = tracks.find({ (t: Track) -> Bool in t.path == dpu.relativePath }),
            index = musicItems.indexOf({ (item: MusicItem) -> Bool in item.id == track.id }) {
                let isDownloadComplete = track.size == dpu.written
                if isDownloadComplete {
                    downloadState.removeValueForKey(track)
                    let isVisible = (isViewLoaded() && view.window != nil)
                    if !isVisible && downloadState.isEmpty {
                        disposeDownloadProgress()
                    }
                } else {
                    downloadState[track] = TrackProgress(track: track, dpu: dpu)
                }
                let itemIndexPath = NSIndexPath(forRow: index, inSection: 0)
                
                Util.onUiThread {
                    self.tableView.reloadRowsAtIndexPaths([itemIndexPath], withRowAnimation: UITableViewRowAnimation.None)
                }
        }
    }
}
