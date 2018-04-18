//
//  LibraryController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class LibraryController: SearchableMusicController, TrackEventDelegate {
    private let log = LoggerFactory.shared.vc(LibraryController.self)
    static let LIBRARY = "library", PLAYER = "player"
    let loadingMessage = "Loading..."
    let noTracksMessage = "No tracks."
    
    var folder: MusicFolder = MusicFolder.empty
    override var musicItems: [MusicItem] { return folder.items }
    var selected: MusicItem? = nil
    
    var header: UIView? = nil
    
    fileprivate var downloadUpdates: Disposable? = nil
    private var reloadOnDidAppear = false
    
    let listener = PlaybackListener()
    
    var isFirstLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.tableView.contentOffset = CGPoint(x: 0, y: self.searchController.searchBar.frame.size.height)
        downloadUpdates = DownloadUpdater.instance.listen(onProgress: onProgress)
        setFeedback(loadingMessage)
        listener.tracks = self
        if let folder = selected {
            loadFolder(folder.id)
        } else {
            loadRoot()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if reloadOnDidAppear {
            renderTable(computeMessage(folder))
        }
        listener.subscribe()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listener.unsubscribe()
        if !DownloadUpdater.instance.isEmpty {
            reloadOnDidAppear = true
        }
    }
    
    func stopUpdates() {
        downloadUpdates?.dispose()
        downloadUpdates = nil
    }
    
    func onTrackChanged(_ track: Track?) {
        // updates any highlighted row
        renderTable()
        // why?
        onUiThread {
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    func loadFolder(_ id: String) {
        library.folder(id, onError: onLoadError, f: onFolder)
    }
    
    func loadRoot() {
        library.rootFolder(onLoadError) { (folder) in
            self.onFolder(folder)
        }
    }
    
    func suggestAddMusicSource() {
        let sheet = UIAlertController(title: "Connect to MusicPimp", message: "To obtain music, connect to a MusicPimp server. Download the server from musicpimp.org.", preferredStyle: .alert)
        let musicSourceAction = UIAlertAction(title: "Add server", style: .default) { _ in
            self.present(UINavigationController(rootViewController: EditEndpointController()), animated: true, completion: nil)
        }
        let notNowAction = UIAlertAction(title: "Not now", style: .cancel, handler: nil)
        sheet.addAction(musicSourceAction)
        sheet.addAction(notNowAction)
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = self.view
        }
        self.present(sheet, animated: true, completion: nil)
    }
    
    func onFolder(_ f: MusicFolder) {
        folder = f
        self.renderTable(computeMessage(folder))
        if folder.items.isEmpty {
            let hasRemoteSources = self.libraryManager.endpoints().exists { (e) -> Bool in
                e.id != Endpoint.Local.id
            }
            if !hasRemoteSources && isFirstLoad {
                self.suggestAddMusicSource()
            } else {
                self.log.info("Not suggesting music source configuration")
            }
        }
        isFirstLoad = false
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return libraryCell(tableView, indexPath: indexPath)
    }
    
    fileprivate func libraryCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let item = musicItems[indexPath.row]
        let isFolder = item as? Folder != nil
        if isFolder {
            let folderCell = identifiedCell(FolderCellId, index: indexPath)
            folderCell.textLabel?.text = item.title
            folderCell.textLabel?.textColor = PimpColors.shared.titles
            folderCell.accessoryType = .disclosureIndicator
            folderCell.layoutMargins = .zero
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
        return UIAlertAction(title: title, style: .default) { (a) -> Void in
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
        return UITableViewRowAction(style: .default, title: title) {
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
    
    // Used when the user clicks a music item
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = itemAt(tableView, indexPath: indexPath) {
            if let folder = item as? Folder {
                let destination = LibraryContainer(folder: folder)
//                destination.folder = folder
                navigationController?.pushViewController(destination, animated: true)
            }
            if let track = item as? Track {
                _ = playAndDownloadCheckedSingle(track)
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension LibraryController {
    func onProgress(track: TrackProgress) {
        if let index = musicItems.indexOf({ (item: MusicItem) -> Bool in item.id == track.track.id }) {
            // log.info("Updating \(track.dpu.written)")
            updateRows(row: index)
        }
    }

    private func updateRows(row: Int) {
        let itemIndexPath = IndexPath(row: row, section: 0)
        onUiThread {
            self.tableView.reloadRows(at: [itemIndexPath], with: .none)
        }
    }
}
