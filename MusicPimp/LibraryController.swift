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
    static let TABLE_CELL_HEIGHT_PLAIN = 44
    let halfCellHeight = LibraryController.TABLE_CELL_HEIGHT_PLAIN / 2
    let loadingMessage = "Loading..."
    let noTracksMessage = "No tracks."
    
    var folder: MusicFolder = MusicFolder.empty
    override var musicItems: [MusicItem] { return folder.items }
    var selected: MusicItem? = nil
    
    var header: UIView? = nil
    
    fileprivate var downloadUpdates: Disposable? = nil
    private var reloadOnDidAppear = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setFeedback(loadingMessage)
        if let folder = selected {
            loadFolder(folder.id)
        } else {
            loadRoot()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let trackListener = player.trackEvent.addHandler(self) { (me) -> (Track?) -> () in
            me.onTrackChanged
        }
        let downloadDisposable = DownloadUpdater.instance.listen(onProgress: onProgress)
        listeners = [trackListener, downloadDisposable]
        if reloadOnDidAppear {
            renderTable(computeMessage(folder))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !DownloadUpdater.instance.isEmpty {
            reloadOnDidAppear = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    func onTrackChanged(track: Track?) {
        // updates any highlighted row
        renderTable()
    }
    
    fileprivate func resetLibrary() {
        loadRoot()
    }
    
    func loadFolder(_ id: String) {
        library.folder(id, onError: onLoadError, f: onFolder)
    }
    
    func loadRoot() {
        library.rootFolder(onLoadError, f: onFolder)
    }
    
    func onFolder(_ f: MusicFolder) {
        folder = f
        self.renderTable(computeMessage(folder)) {
            self.tableView.tableHeaderView = self.searchController.searchBar
            self.tableView.contentOffset = CGPoint(x: 0, y: self.searchController.searchBar.frame.size.height)
        }
    }
    
    func computeMessage(_ folder: MusicFolder) -> String? {
        let isEmpty = folder.items.isEmpty
        if let selected = selected {
            return isEmpty ? "No tracks in folder \(selected.title)." : nil
        } else {
            // selected == nil means we are in the root library folder
            if isEmpty {
                if library.isLocal {
                    return "The music library is empty. To get started, download and install the MusicPimp server from www.musicpimp.org, then add it as a music source under Settings."
                } else {
                    return "The music library is empty."
                }
            } else {
                return nil
            }
        }
    }
    
    override func clearItems() {
        // TODO keep folder path, but don't show items
        //folder = MusicFolder.empty
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return libraryCell(tableView, indexPath: indexPath)
    }
    
    fileprivate func libraryCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let item = musicItems[(indexPath as NSIndexPath).row]
        let isFolder = item as? Folder != nil
        if isFolder {
            let folderCell = identifiedCell("FolderCell", index: indexPath)
            folderCell.textLabel?.text = item.title
            folderCell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            return folderCell
        } else {
            if let track = item as? Track, let pimpCell = trackCell(track, index: indexPath) {
                paintTrackCell(cell: pimpCell, track: track, isHighlight: self.player.current().track?.id == track.id, downloadState: DownloadUpdater.instance.progressFor(track: track))
                return pimpCell
            } else {
                // we should never get here
                return super.tableView(tableView, cellForRowAt: indexPath)
            }
        }
    }
    
    func sheetAction(_ title: String, item: MusicItem, onTrack: @escaping (Track) -> Void, onFolder: @escaping (Folder) -> Void) -> UIAlertAction {
        return UIAlertAction(title: title, style: UIAlertActionStyle.default) { (a) -> Void in
            if let track = item as? Track {
                onTrack(track)
            }
            if let folder = item as? Folder {
                onFolder(folder)
            }
        }
    }
    
    // When this method is defined, cells become swipeable
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let playAction = musicItemAction(
            tableView,
            title: "Play",
            onTrack: { (t) -> Void in _ = self.playTrack(t) },
            onFolder: { (f) -> Void in _ = self.playFolder(f.id) }
        )
        let addAction = musicItemAction(
            tableView,
            title: "Add",
            onTrack: { (t) -> Void in _ = self.addTrack(t) },
            onFolder: { (f) -> Void in _ = self.addFolder(f.id) }
        )
        return [playAction, addAction]
    }
    
    func musicItemAction(_ tableView: UITableView, title: String, onTrack: @escaping (Track) -> Void, onFolder: @escaping (Folder) -> Void) -> UITableViewRowAction {
        return UITableViewRowAction(style: UITableViewRowActionStyle.default, title: title) {
            (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
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
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = itemAt(tableView, indexPath: indexPath), let track = item as? Track {
            _ = playAndDownload(track)
        }
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
    }
    
    // Performs segue if the user clicked a folder
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == LibraryController.LIBRARY {
            if let row = self.tableView.indexPathForSelectedRow {
                let index = (row as NSIndexPath).item
                return musicItems.count > index && musicItems[index] is Folder
            } else {
                info("Cannot navigate to item at row \(index)")
                return false
            }
        }
        if identifier == "Test" {
            return true
        }
        info("Unknown identifier: \(identifier)")
        return false
    }
    
    // Used when the user taps a folder, initiating a navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination
        if let destination = dest as? LibraryParent {
            if let row = self.tableView.indexPathForSelectedRow {
                destination.folder = musicItems[row.item]
            } else {
                error("No index, destination \(dest)")
            }
        } else {
            error("Unknown destination controller \(dest)")
        }
    }
    
    @IBAction func unwindToItems(_ segue: UIStoryboardSegue) {
        let src = segue.source as? LibraryController
        if let id = src?.selected?.id {
            loadFolder(id)
        } else {
            loadRoot()
        }
    }
}

extension LibraryController {
    func onProgress(track: TrackProgress) {
        //Log.info("track \(track.track.title) \(track.dpu.written)")
        if let index = musicItems.indexOf({ (item: MusicItem) -> Bool in item.id == track.track.id }) {
            updateRows(row: index)
        }
    }

    private func updateRows(row: Int) {
        let itemIndexPath = IndexPath(row: row, section: 0)
        Util.onUiThread {
            self.tableView.reloadRows(at: [itemIndexPath], with: UITableViewRowAnimation.none)
        }
    }
}
