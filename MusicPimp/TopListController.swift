import Foundation

class TopListController<T: TopEntry>: BaseMusicController, LibraryDelegate {
    private let log = LoggerFactory.shared.vc(TopListController.self)
    let defaultCellKey = "PimpMusicItemCell"
    let itemsPerLoad = 100
    let minItemsRemainingBeforeLoadMore = 20
    var loadingMessage: String { "Loading..." }
    var emptyMessage: String { "No tracks." }
    var failedToLoadMessage: String { "Failed to load tracks." }
    var header: String { "Top Tracks" }
    var entries: [T] = []
    var tracks: [Track] { entries.map { $0.entry } }
    override var musicItems: [MusicItem] { tracks }
    var showHeader: Bool = false
    // Unless this is used, the infinite scroll does not maintain proper scroll position when adding items to the bottom
    let cellHeight: CGFloat = MainSubCell.height
    let listener = LibraryListener()
    var hasLoaded = false
    
    var maybeFeedback: String? { return self.tracks.count == 0 ? (hasLoaded ? self.emptyMessage : self.loadingMessage) : nil }
    
    private var reloadOnDidAppear = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = cellHeight
        refresh()
        listener.delegate = self
        listener.subscribe()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if reloadOnDidAppear {
            reloadTable(feedback: maybeFeedback)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reloadOnDidAppear = !DownloadUpdater.instance.isEmpty
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let cell = cellFor(track: entries[index], indexPath: indexPath)
        return cell
    }
    
    func cellFor(track: T, indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
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
        PimpHeaderFooter.withText(header)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        showHeader ? 36 : 0
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
            _ = self.playTracksChecked(self.tracks.drop(row))
        }
    }
    
    func onLibraryUpdated(to newLibrary: LibraryType) {
        refresh()
    }
    
    // Override this to load and render data
    func refresh() {}
    
    // Override to load more for infinite scroll
    func loadMore() { }
    
    func onTopLoaded(_ results: [T]) {
        hasLoaded = true
        withMessage(nil) {
            self.entries = results
        }
    }
    
    func onMoreResults(_ from: Int, results: [T]) {
        onUiThread {
            self.entries = self.appendConditionally(self.entries, from: from, newContent: results)
            self.onMore(from, newRows: results.count, expectedSize: self.entries.count)
        }
    }
    
    private func onMore(_ from: Int, newRows: Int, expectedSize: Int) {
        let rows: [Int] = Array(from..<from+newRows)
        let indexPaths = rows.map { row in IndexPath(item: row, section: 0) }
        if (from+newRows) == expectedSize {
            self.tableView.insertRows(at: indexPaths, with: .bottom)
            self.log.info("Updated table with \(indexPaths.count) more items from \(from) to \(from+newRows-1)")
        }
    }
    
    func appendConditionally<T>(_ src: [T], from: Int, newContent: [T]) -> [T] {
        let oldSize = src.count
        if oldSize == from {
            return src + newContent
        } else {
            log.warn("Not appending because of list size mismatch. Was: \(oldSize), expected \(from)")
            return src
        }
    }
    
    func onTopError(_ e: Error) {
        onError(e)
        withMessage(failedToLoadMessage) {
            self.entries = []
        }
    }
}
