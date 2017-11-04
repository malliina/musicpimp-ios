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
    case popular = 0, recent
}

class PlaylistController: BaseMusicController {
    private let log = LoggerFactory.vc("PlaylistController")
    let defaultCellKey = "PimpMusicItemCell"
    let itemsPerLoad = 100
    let minItemsRemainingBeforeLoadMore = 20
    var emptyMessage: String {
        get {
            switch mode {
            case .popular: return "No popular tracks."
            case .recent: return "No recent tracks."
            }
        }
    }
    var mode: ListMode = .popular
    var recent: [RecentEntry] = []
    var popular: [PopularEntry] = []
    var tracks: [Track] {
        get {
            switch mode {
            case .popular: return popular.map { $0.track }
            case .recent: return recent.map { $0.track }
            }
        }
    }
    override var musicItems: [MusicItem] { return tracks }
    private var reloadOnDidAppear = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(SnapMainSubCell.self, forCellReuseIdentifier: FeedbackTable.mainAndSubtitleCellKey)
        maybeRefresh(mode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if reloadOnDidAppear {
            reRenderTable()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reloadOnDidAppear = !DownloadUpdater.instance.isEmpty
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        switch mode {
        case .popular:
            let cell: SnapMainSubCell = loadCell(FeedbackTable.mainAndSubtitleCellKey, index: indexPath)
            decoratePopularCell(cell, track: popular[index])
            cell.accessoryDelegate = self
            return cell
        case .recent:
            let cell: SnapMainSubCell = loadCell(FeedbackTable.mainAndSubtitleCellKey, index: indexPath)
            decorateRecentCell(cell, track: recent[index])
            cell.accessoryDelegate = self
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        maybeLoadMore(indexPath.row)
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
        }
    }
    
    // parent calls this one
    func maybeRefresh(_ targetMode: ListMode) {
        mode = targetMode
        switch targetMode {
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
    
    func decorateRecentCell(_ cell: SnapMainSubCell, track: RecentEntry) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        let formattedDate = formatter.string(from: track.when)
        decorateTwoLines(cell, first: track.track.title, second: formattedDate)
    }
    
    func decoratePopularCell(_ cell: SnapMainSubCell, track: PopularEntry) {
        decorateTwoLines(cell, first: track.track.title, second: "\(track.playbackCount) plays")
    }
    
    func decorateTwoLines(_ cell: SnapMainSubCell, first: String, second: String) {
        cell.main.text = first
        cell.sub.text = second
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        limitChecked {
            let track = self.tracks[index]
            _ = self.playTrack(track)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
    
    override func playTrackAccessoryAction(_ track: Track, row: Int) -> UIAlertAction {
        // starts playback of the selected track, and appends the rest to the playlist
        return accessoryAction("Start Playback Here") { _ in
            _ = self.playTracks(self.tracks.drop(row))
        }
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
                self.log.info("Updated table with \(indexPaths.count) more items")
            }
        }
    }
    
    func appendConditionally<T>(_ src: [T], from: Int, newContent: [T]) -> [T] {
        let oldSize = src.count
        if oldSize == from {
            return src + newContent
            //src.appendContentsOf(newContent)
        } else {
            log.info("Not appending because of list size mismatch. Was: \(oldSize), expected \(from)")
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
}
