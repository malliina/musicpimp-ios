//
//  PlaylistController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

enum ListMode: Int {
    case playlist = 0, popular, recent
}

class PlaylistController: BaseMusicController {
    let defaultCellKey = "PimpMusicItemCell"
    let itemsPerLoad = 100
    let minItemsRemainingBeforeLoadMore = 20
    let emptyMessage = "The playlist is empty."
    var mode: ListMode = .playlist
    var current: Playlist = Playlist.empty
    var recent: [RecentEntry] = []
    var popular: [PopularEntry] = []
    var tracks: [Track] {
        get {
            switch mode {
            case .playlist: return current.tracks
            case .popular: return popular.map { $0.track }
            case .recent: return recent.map { $0.track }
            }
        }
    }
    override var musicItems: [MusicItem] { return tracks }
    var selected: MusicItem? = nil
    
    fileprivate var downloadState: [Track: TrackProgress] = [:]
    fileprivate var lastDownloadUpdate: DispatchTime? = nil
    let fps: UInt64 = 10
    
    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNib(PlaylistController.mainAndSubtitleCellKey)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        downloadState = [:]
        let playlistDisposable = player.playlist.playlistEvent.addHandler(self) { (plc: PlaylistController) -> (Playlist) -> () in
            plc.onNewPlaylist
        }
        let indexDisposable = player.playlist.indexEvent.addHandler(self) { (plc: PlaylistController) -> (Int?) -> () in
            plc.onIndexChanged
        }
        let downloadProgressDisposable = BackgroundDownloader.musicDownloader.events.addHandler(self) { (plc) -> (DownloadProgressUpdate) -> () in
            plc.onDownloadProgressUpdate
        }
        listeners = [playlistDisposable, indexDisposable, downloadProgressDisposable]
        let state = player.current()
        let currentPlaylist = Playlist(tracks: state.playlist, index: state.playlistIndex)
        onNewPlaylist(currentPlaylist)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = (indexPath as NSIndexPath).row
        switch mode {
        case .playlist:
            let cell: PimpMusicItemCell = loadCell(defaultCellKey, index: indexPath)
            let track = tracks[index]
            cell.titleLabel?.text = track.title
            paintTrackCell(cell: cell, track: track, isHighlight: index == current.index, downloadState: downloadState)
            return cell
        case .popular:
            let cell: MainAndSubtitleCell = loadCell(FeedbackTable.mainAndSubtitleCellKey, index: indexPath)
            decoratePopularCell(cell, track: popular[index])
            return cell
        case .recent:
            let cell: MainAndSubtitleCell = loadCell(FeedbackTable.mainAndSubtitleCellKey, index: indexPath)
            decorateRecentCell(cell, track: recent[index])
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        maybeLoadMore((indexPath as NSIndexPath).row)
    }
    
    fileprivate func maybeLoadMore(_ currentRow: Int) {
        let trackCount = tracks.count
        if currentRow + minItemsRemainingBeforeLoadMore == trackCount {
            loadMore()
        }
    }
    
    func loadMore() {
        // TODO DRY by refactoring recent and popular handling into reusable modules
        switch mode {
        case .popular:
            let oldSize = popular.count
            library.popular(oldSize, until: oldSize + itemsPerLoad, onError: onPopularError) { content in
                self.onMorePopulars(oldSize, populars: content)
            }
        case .recent:
            let oldSize = recent.count
            library.recent(oldSize, until: oldSize + itemsPerLoad, onError: onRecentError) { content in
                self.onMoreRecents(oldSize, recents: content)
            }
        default:
            Log.info("Lazy not implemented for \(mode)")
        }
    }
    
    override func cellHeight() -> CGFloat {
        switch mode {
        case .playlist: return defaultCellHeight
        default: return PlaylistController.mainAndSubtitleCellHeight
        }
    }
    
    func dragClicked(_ dragButton: UIBarButtonItem) {
        let isEditing = self.tableView.isEditing
        self.tableView.setEditing(!isEditing, animated: true)
        let title = isEditing ? "Edit" : "Done"
        dragButton.style = isEditing ? UIBarButtonItemStyle.plain : UIBarButtonItemStyle.done
        dragButton.title = title
    }
    
    // parent calls this one
    func maybeRefresh(_ targetMode: ListMode) {
        mode = targetMode
        //dragButton.enabled = targetMode == .Playlist
        switch targetMode {
        case .playlist:
            reRenderTable()
        case .popular:
            popular = []
            renderTable("Loading popular tracks...")
            library.popular(0, until: itemsPerLoad, onError: onPopularError, f: onPopularsLoaded)
        case .recent:
            recent = []
            renderTable("Loading recent tracks...")
            library.recent(0, until: itemsPerLoad, onError: onRecentError, f: onRecentsLoaded)
        }
    }
    
    func decorateRecentCell(_ cell: MainAndSubtitleCell, track: RecentEntry) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        let formattedDate = formatter.string(from: track.when as Date)
        decorateTwoLines(cell, first: track.track.title, second: formattedDate)
        installTrackAccessoryView(cell)
    }
    
    func decoratePopularCell(_ cell: MainAndSubtitleCell, track: PopularEntry) {
        decorateTwoLines(cell, first: track.track.title, second: "\(track.playbackCount) plays")
        installTrackAccessoryView(cell)
    }
    
    func decorateTwoLines(_ cell: MainAndSubtitleCell, first: String, second: String) {
        cell.mainTitle?.text = first
        cell.subtitle?.text = second
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = (indexPath as NSIndexPath).row
        limitChecked {
            switch self.mode {
            case .playlist:
                self.player.skip(index)
            default:
                let track = self.tracks[index]
                self.playTrack(track)
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return mode == .playlist
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if mode == .playlist {
            let index = (indexPath as NSIndexPath).row
            tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
            limitChecked {
                self.player.playlist.removeIndex(index)
            }
        } else {
            super.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceRow = (sourceIndexPath as NSIndexPath).row
        let destinationRow = (destinationIndexPath as NSIndexPath).row
        let newTracks = Arrays.move(sourceRow, destIndex: destinationRow, xs: current.tracks)
        let newIndex = computeNewIndex(sourceRow, dest: destinationRow)
        current = Playlist(tracks: newTracks, index: newIndex)
        player.playlist.move(sourceRow, dest: destinationRow)
    }
    
    func computeNewIndex(_ src: Int, dest: Int) -> Int? {
        if let index = current.index {
            return LocalPlaylist.newPlaylistIndex(index, src: src, dest: dest)
        }
        return nil
    }
    
    override func playTrackAccessoryAction(_ track: Track, row: Int) -> UIAlertAction {
        switch mode {
        case .playlist:
            return super.playTrackAccessoryAction(track, row: row)
        default:
            // starts playback of the selected track, and appends the rest to the playlist
            return accessoryAction("Start Playback Here") { _ in
                self.playTracks(self.tracks.drop(row))
            }
        }
    }

    func onNewPlaylist(_ playlist: Playlist) {
        self.current = playlist
        reRenderTable()
    }
    
    func onRecentsLoaded(_ recents: [RecentEntry]) {
        recent = recents
        reRenderTable()
    }
    
    func onPopularsLoaded(_ populars: [PopularEntry]) {
        popular = populars
        reRenderTable()
    }
    
    func onMoreRecents(_ from: Int, recents: [RecentEntry]) {
        recent = appendConditionally(recent, from: from, newContent: recents)
        onMore(from, newRows: recents.count, expectedSize: recent.count, expectedMode: .recent)
    }
    
    func onMorePopulars(_ from: Int, populars: [PopularEntry]) {
        popular = appendConditionally(popular, from: from, newContent: populars)
        onMore(from, newRows: populars.count, expectedSize: popular.count, expectedMode: .popular)
    }
    
    func onMore(_ from: Int, newRows: Int, expectedSize: Int, expectedMode: ListMode) {
        let rows: [Int] = Array(from..<from+newRows)
        let indexPaths = rows.map { row in IndexPath(item: row, section: 0) }
        onUiThread {
            if self.mode == expectedMode && (from+newRows) == expectedSize {
                self.tableView.insertRows(at: indexPaths, with: .bottom)
                Log.info("Updated table with \(indexPaths.count) more items")
            }
        }
    }
    
    func appendConditionally<T>(_ src: [T], from: Int, newContent: [T]) -> [T] {
        let oldSize = src.count
        if oldSize == from {
            return src + newContent
            //src.appendContentsOf(newContent)
        } else {
            Log.info("Not appending because of list size mismatch. Was: \(oldSize), expected \(from)")
            return src
        }
    }
    
    func onPopularError(_ e: PimpError) {
        popular = []
        onLoadError(e, message: "Failed to load popular tracks.")
    }
    
    func onRecentError(_ e: PimpError) {
        recent = []
        onLoadError(e, message: "Failed to load recent tracks.")
    }
    
    func onLoadError(_ e: PimpError, message: String) {
        onError(e)
        renderTable(message)
    }

    func reRenderTable() {
        renderTable(self.tracks.count == 0 ? self.emptyMessage : nil)
    }
    
    func onIndexChanged(_ index: Int?) {
        self.current = Playlist(tracks: current.tracks, index: index)
        renderTable()
    }
    
    func onDownloadProgressUpdate(_ dpu: DownloadProgressUpdate) {
        if mode == .playlist {
            if let track = current.tracks.find({ (t: Track) -> Bool in t.path == dpu.relativePath }),
                let index = current.tracks.indexOf({ (item: Track) -> Bool in item.path == track.path }) {
                let isDownloadComplete = track.size == dpu.written
                if isDownloadComplete {
                    downloadState.removeValue(forKey: track)
                } else {
                    downloadState[track] = TrackProgress(track: track, dpu: dpu)
                }
                let itemIndexPath = IndexPath(row: index, section: 0)
                
                let now = DispatchTime.now()
                let shouldUpdate = isDownloadComplete || LibraryController.enoughTimePassed(now: now, last: lastDownloadUpdate, fps: fps)
                
                if shouldUpdate {
                    lastDownloadUpdate = now
                    onUiThread {
                        // The app crashed if reloading a row while concurrently dragging and dropping rows.
                        // TODO investigate and fix, but as a workaround, we don't update the download progress when editing.
                        if !self.tableView.isEditing && index < self.tracks.count {
                            self.tableView.reloadRows(at: [itemIndexPath], with: UITableViewRowAnimation.none)
                        }
                    }
                }
            }
        }
    }
}
