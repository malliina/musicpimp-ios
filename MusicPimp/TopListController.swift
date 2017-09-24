//
//  TopListController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class TopListController<T: TopEntry>: BaseMusicController {
    private let log = LoggerFactory.vc("TopListController")
    let defaultCellKey = "PimpMusicItemCell"
    let itemsPerLoad = 100
    let minItemsRemainingBeforeLoadMore = 20
    var emptyMessage: String { get { return "No tracks." } }
    var failedToLoadMessage: String { get { return "Failed to load tracks."} }
    var header: String { return "Top Tracks" }
    var entries: [T] = []
    var tracks: [Track] { get { return entries.map { $0.track } } }
    override var musicItems: [MusicItem] { return tracks }
    
    private var reloadOnDidAppear = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(SnapMainSubCell.self, forCellReuseIdentifier: FeedbackTable.mainAndSubtitleCellKey)
        refresh()
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
        let cell: SnapMainSubCell = loadCell(FeedbackTable.mainAndSubtitleCellKey, index: indexPath)
        decorate(cell: cell, track: entries[index])
        cell.accessoryDelegate = self
        return cell
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
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        maybeLoadMore(indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return PimpHeaderFooter.withText(header)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    fileprivate func maybeLoadMore(_ currentRow: Int) {
        let trackCount = tracks.count
        if currentRow + minItemsRemainingBeforeLoadMore == trackCount {
            loadMore()
        }
    }
    
    override func playTrackAccessoryAction(_ track: Track, row: Int) -> UIAlertAction {
        // starts playback of the selected track, and appends the rest to the playlist
        return accessoryAction("Start Playback Here") { _ in
            _ = self.playTracks(self.tracks.drop(row))
        }
    }
    
    // Override to populate cell
    func decorate(cell: SnapMainSubCell, track: T) {
    }
    
    // Override this to load and render data
    func refresh() {}
    
    // Override to load more for infinite scroll
    func loadMore() { }
    
    func decorateTwoLines(_ cell: SnapMainSubCell, first: String, second: String) {
        cell.main.text = first
        cell.sub.text = second
    }
    
    func onTopLoaded(_ results: [T]) {
        entries = results
        reRenderTable()
    }
    
    func onMoreResults(_ from: Int, results: [T]) {
        entries = appendConditionally(entries, from: from, newContent: results)
        onMore(from, newRows: results.count, expectedSize: entries.count)
    }
    
    func onMore(_ from: Int, newRows: Int, expectedSize: Int) {
        let rows: [Int] = Array(from..<from+newRows)
        let indexPaths = rows.map { row in IndexPath(item: row, section: 0) }
        onUiThread {
            if (from+newRows) == expectedSize {
                self.tableView.insertRows(at: indexPaths, with: .bottom)
                self.log.info("Updated table with \(indexPaths.count) more items")
            }
        }
    }
    
    func appendConditionally<T>(_ src: [T], from: Int, newContent: [T]) -> [T] {
        let oldSize = src.count
        if oldSize == from {
            return src + newContent
        } else {
            log.info("Not appending because of list size mismatch. Was: \(oldSize), expected \(from)")
            return src
        }
    }
    
    func onTopError(_ e: PimpError) {
        entries = []
        onLoadError(e, message: failedToLoadMessage)
    }
    
    func onLoadError(_ e: PimpError, message: String) {
        onError(e)
        renderTable(message)
    }
    
    func reRenderTable() {
        renderTable(self.tracks.count == 0 ? self.emptyMessage : nil)
    }
}
