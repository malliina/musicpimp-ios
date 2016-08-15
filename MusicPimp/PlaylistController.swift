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
    case Playlist = 0, Popular, Recent
}

class PlaylistController: BaseMusicController {
    let defaultCellKey = "PimpMusicItemCell"
    let maxPopularRecentCount = 100
    let emptyMessage = "The playlist is empty."
    var mode: ListMode = .Playlist
    var current: Playlist = Playlist.empty
    var recent: [RecentEntry] = []
    var popular: [PopularEntry] = []
    var tracks: [Track] {
        get {
            switch mode {
            case .Playlist: return current.tracks
            case .Popular: return popular.map { $0.track }
            case .Recent: return recent.map { $0.track }
            }
        }
    }
    override var musicItems: [MusicItem] { return tracks }
    var selected: MusicItem? = nil
    var listeners: [Disposable] = []
    private var downloadState: [Track: TrackProgress] = [:]
    
    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNib(PlaylistController.mainAndSubtitleCellKey)
    }
    
    override func viewWillAppear(animated: Bool) {
        downloadState = [:]
        let playlistDisposable = player.playlist.playlistEvent.addHandler(self) { (plc: PlaylistController) -> Playlist -> () in
            plc.onNewPlaylist
        }
        let indexDisposable = player.playlist.indexEvent.addHandler(self) { (plc: PlaylistController) -> Int? -> () in
            plc.onIndexChanged
        }
        let downloadProgressDisposable = BackgroundDownloader.musicDownloader.events.addHandler(self) { (plc) -> DownloadProgressUpdate -> () in
            plc.onDownloadProgressUpdate
        }
        listeners = [playlistDisposable, indexDisposable, downloadProgressDisposable]
        let state = player.current()
        let currentPlaylist = Playlist(tracks: state.playlist, index: state.playlistIndex)
        onNewPlaylist(currentPlaylist)
    }
    
    override func viewWillDisappear(animated: Bool) {
        stopListening()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let index = indexPath.row
        switch mode {
        case .Playlist:
            let isCurrent = index == current.index
            let isHighlight = isCurrent
            let cell: PimpMusicItemCell = loadCell(defaultCellKey, index: indexPath)
            decorateCell(cell, track: tracks[index], isHighlight: isHighlight)
            return cell
        case .Popular:
            let cell: MainAndSubtitleCell = loadCell(FeedbackTable.mainAndSubtitleCellKey, index: indexPath)
            decoratePopularCell(cell, track: popular[index])
            return cell
        case .Recent:
            let cell: MainAndSubtitleCell = loadCell(FeedbackTable.mainAndSubtitleCellKey, index: indexPath)
            decorateRecentCell(cell, track: recent[index])
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeight()
    }
    
    override func cellHeight() -> CGFloat {
        switch mode {
        case .Playlist: return defaultCellHeight
        default: return PlaylistController.mainAndSubtitleCellHeight
        }
    }
    
    func stopListening() {
        for listener in listeners {
            listener.dispose()
        }
        listeners = []
    }
    
    func dragClicked(dragButton: UIBarButtonItem) {
        let isEditing = self.tableView.editing
        self.tableView.setEditing(!isEditing, animated: true)
        let title = isEditing ? "Edit" : "Done"
        dragButton.style = isEditing ? UIBarButtonItemStyle.Plain : UIBarButtonItemStyle.Done
        dragButton.title = title
    }
    
    // parent calls this one
    func maybeRefresh(targetMode: ListMode) {
        mode = targetMode
        //dragButton.enabled = targetMode == .Playlist
        switch targetMode {
        case .Playlist:
            reRenderTable()
        case .Popular:
            popular = []
            renderTable("Loading popular tracks...")
            library.popular(maxPopularRecentCount, onError: onPopularError, f: onPopularsLoaded)
        case .Recent:
            recent = []
            renderTable("Loading recent tracks...")
            library.recent(maxPopularRecentCount, onError: onRecentError, f: onRecentsLoaded)
        }
    }
    
    func decorateRecentCell(cell: MainAndSubtitleCell, track: RecentEntry) {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle
        formatter.doesRelativeDateFormatting = true
        let formattedDate = formatter.stringFromDate(track.when)
        decorateTwoLines(cell, first: track.track.title, second: formattedDate)
        installTrackAccessoryView(cell)
    }
    
    func decoratePopularCell(cell: MainAndSubtitleCell, track: PopularEntry) {
        decorateTwoLines(cell, first: track.track.title, second: "\(track.playbackCount) plays")
        installTrackAccessoryView(cell)
    }
    
    func decorateTwoLines(cell: MainAndSubtitleCell, first: String, second: String) {
        cell.mainTitle?.text = first
        cell.subtitle?.text = second
    }
    
    func decorateCell(cell: PimpMusicItemCell, track: Track, isHighlight: Bool) {
        if let downloadProgress = downloadState[track] {
            //info("Setting progress to \(downloadProgress.progress)")
            cell.progressView.progress = downloadProgress.progress
            cell.progressView.hidden = false
        } else {
            cell.progressView.hidden = true
        }
        cell.titleLabel?.text = track.title
        let (titleColor, selectionStyle) = isHighlight ? (UIColor.blueColor(), UITableViewCellSelectionStyle.Blue) : (UIColor.blackColor(), UITableViewCellSelectionStyle.Default)
        cell.titleLabel?.textColor = titleColor
        cell.selectionStyle = selectionStyle
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let index = indexPath.row
        limitChecked {
            switch self.mode {
            case .Playlist:
                self.player.skip(index)
            default:
                let track = self.tracks[index]
                self.playTrack(track)
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return mode == .Playlist
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if mode == .Playlist {
            let index = indexPath.row
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
            limitChecked {
                self.player.playlist.removeIndex(index)
            }
        } else {
            super.tableView(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let sourceRow = sourceIndexPath.row
        let destinationRow = destinationIndexPath.row
        let newTracks = Arrays.move(sourceRow, destIndex: destinationRow, xs: current.tracks)
        let newIndex = computeNewIndex(sourceRow, dest: destinationRow)
        current = Playlist(tracks: newTracks, index: newIndex)
        player.playlist.move(sourceRow, dest: destinationRow)
    }
    
    func computeNewIndex(src: Int, dest: Int) -> Int? {
        if let index = current.index {
            return LocalPlaylist.newPlaylistIndex(index, src: src, dest: dest)
        }
        return nil
    }
    
    override func playTrackAccessoryAction(track: Track, row: Int) -> UIAlertAction {
        switch mode {
        case .Playlist:
            return super.playTrackAccessoryAction(track, row: row)
        default:
            // starts playback of the selected track, and appends the rest to the playlist
            return accessoryAction("Start Playback Here") { _ in
                self.playTracks(self.tracks.drop(row))
            }
        }
    }

    func onNewPlaylist(playlist: Playlist) {
        self.current = playlist
        reRenderTable()
    }
    
    func onRecentsLoaded(recents: [RecentEntry]) {
        recent = recents
        reRenderTable()
    }
    
    func onPopularsLoaded(populars: [PopularEntry]) {
        popular = populars
        reRenderTable()
    }
    
    func onPopularError(e: PimpError) {
        popular = []
        onLoadError(e, message: "Failed to load popular tracks.")
    }
    
    func onRecentError(e: PimpError) {
        recent = []
        onLoadError(e, message: "Failed to load recent tracks.")
    }
    
    func onLoadError(e: PimpError, message: String) {
        onError(e)
        renderTable(message)
    }

    func reRenderTable() {
        renderTable(self.tracks.count == 0 ? self.emptyMessage : nil)
    }
    
    func onIndexChanged(index: Int?) {
        self.current = Playlist(tracks: current.tracks, index: index)
        renderTable()
    }
    
    func onDownloadProgressUpdate(dpu: DownloadProgressUpdate) {
        //info("Written \(dpu.written) of \(dpu.relativePath)")
        if let track = tracks.find({ (t: Track) -> Bool in t.path == dpu.relativePath }),
            index = tracks.indexOf({ (item: Track) -> Bool in item.path == track.path }) {
            let isDownloadComplete = track.size == dpu.written
            if isDownloadComplete {
                downloadState.removeValueForKey(track)
            } else {
                downloadState[track] = TrackProgress(track: track, dpu: dpu)
            }
            let itemIndexPath = NSIndexPath(forRow: index, inSection: 0)
            
            onUiThread {
                // The app crashed if reloading a row while concurrently dragging and dropping rows.
                // TODO investigate and fix, but as a workaround, we don't update the download progress when editing.
                if !self.tableView.editing {
                    self.tableView.reloadRowsAtIndexPaths([itemIndexPath], withRowAnimation: UITableViewRowAnimation.None)
                }
            }
        }
    }
}
