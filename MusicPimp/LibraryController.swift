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
    fileprivate var downloadState: [Track: TrackProgress] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setFeedback(loadingMessage)
        if let folder = selected {
            loadFolder(folder.id)
        } else {
            loadRoot()
        }
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
        self.renderTable(computeMessage(folder))
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
//            folderCell.textLabel?.textColor = PimpColors.titles
            folderCell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            return folderCell
        } else {
            if let track = item as? Track, let pimpCell = trackCell(track, index: indexPath) {
                if let downloadProgress = downloadState[track] {
                    //info("Setting progress to \(downloadProgress.progress)")
                    pimpCell.progressView.progress = downloadProgress.progress
                    pimpCell.progressView.isHidden = false
                } else {
                    pimpCell.progressView.isHidden = true
                }
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
            playAndDownload(track)
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
                let folder = musicItems[(row as NSIndexPath).item]
                destination.folder = folder
            } else {
                Log.error("No index, destination \(dest)")
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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        downloadState = [:]
        downloadUpdates = BackgroundDownloader.musicDownloader.events.addHandler(self) { (lc) -> (DownloadProgressUpdate) -> () in
            lc.onDownloadProgressUpdate
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if downloadState.isEmpty {
            disposeDownloadProgress()
        }
    }
    
    func disposeDownloadProgress() {
        downloadUpdates?.dispose()
        downloadUpdates = nil
    }
    
    func onDownloadProgressUpdate(_ dpu: DownloadProgressUpdate) {
        let tracks = folder.tracks
        if let track = tracks.find({ (t: Track) -> Bool in t.path == dpu.relativePath }),
            let index = musicItems.indexOf({ (item: MusicItem) -> Bool in item.id == track.id }) {
                let isDownloadComplete = track.size == dpu.written
                if isDownloadComplete {
                    downloadState.removeValue(forKey: track)
                    let isVisible = (isViewLoaded && view.window != nil)
                    if !isVisible && downloadState.isEmpty {
                        disposeDownloadProgress()
                    }
                } else {
                    downloadState[track] = TrackProgress(track: track, dpu: dpu)
                }
                let itemIndexPath = IndexPath(row: index, section: 0)
                
                Util.onUiThread {
                    self.tableView.reloadRows(at: [itemIndexPath], with: UITableViewRowAnimation.none)
                }
        }
    }
}
