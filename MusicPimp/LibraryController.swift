//
//  LibraryController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class TrackProgress {
    let track: Track
    let dpu: DownloadProgressUpdate
    
    var progress: Float { return Float(Double(dpu.written.toBytes) / Double(track.size.toBytes)) }
    
    init(track: Track, dpu: DownloadProgressUpdate) {
        self.track = track
        self.dpu = dpu
    }
}

class LibraryController: BaseMusicController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    /// State restoration values.
    enum RestorationKeys : String {
        case viewControllerTitle
        case searchControllerIsActive
        case searchBarText
        case searchBarIsFirstResponder
    }
    
    struct SearchControllerRestorableState {
        var wasActive = false
        var wasFirstResponder = false
    }
    
    /// Restoration state for UISearchController
    var restoredState = SearchControllerRestorableState()

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
    
    var resultsController: SearchResultsController!
    var searchController: UISearchController!
    private var latestSearchString: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
//        activityView.frame = CGRect(x: 0, y: 0, width: 320, height: LibraryController.TABLE_CELL_HEIGHT_PLAIN)
//        activityView.startAnimating()
//        self.tableView.tableHeaderView = activityView
        
//        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
//        let feedbackLabel = UILabel(frame: CGRect(x: 16, y: 0, width: 300, height: 44))
//        feedbackLabel.textColor = UIColor.blueColor()
//        headerView.addSubview(feedbackLabel)
//        self.feedback = feedbackLabel
//        self.header = headerView
        
        initSearch()
        
        feedbackMessage = "Loading..."
        if let folder = selected {
            self.navigationItem.title = folder.title
            loadFolder(folder.id)
        } else {
            loadRoot()
        }
    }
    
    private func initSearch() {
        resultsController = SearchResultsController()
        resultsController.tableView.delegate = self
        searchController = UISearchController(searchResultsController: resultsController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "Search track or artist"
        tableView.tableHeaderView = searchController.searchBar
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        definesPresentationContext = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        downloadState = [:]
        downloadUpdates = BackgroundDownloader.musicDownloader.events.addHandler(self, handler: { (lc) -> DownloadProgressUpdate -> () in
            lc.onDownloadProgressUpdate
        })
    }
    
    private func restoreSearch() {
        // Restore the searchController's active state.
        if restoredState.wasActive {
            searchController.active = restoredState.wasActive
            restoredState.wasActive = false
            
            if restoredState.wasFirstResponder {
                searchController.searchBar.becomeFirstResponder()
                restoredState.wasFirstResponder = false
            }
        }
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
    
    @IBAction func refreshClicked(sender: UIBarButtonItem) {
        info("Refresh from \(self)")
        self.navigationController?.popToRootViewControllerAnimated(true)
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
    
    func onLoadError(error: PimpError) {
        feedbackMessage = "An error occurred"
        onError(error)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if musicItems.count == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(BaseMusicController.feedbackIdentifier, forIndexPath: indexPath)
            let statusMessage = feedbackMessage ?? "No tracks"
            cell.textLabel?.text = statusMessage
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
    
    private func itemAt(tableView: UITableView, indexPath: NSIndexPath) -> MusicItem? {
        let items = tableView == self.tableView ? musicItems : resultsController.musicItems
        let row = indexPath.row
        if items.count > row {
            return items[row]
        } else {
            return nil
        }
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
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func presentSearchController(searchController: UISearchController) {
        
    }
    
    func willPresentSearchController(searchController: UISearchController) {
        
    }
    
    func didPresentSearchController(searchController: UISearchController) {
        
    }
    
    func willDismissSearchController(searchController: UISearchController) {
        
    }
    
    func didDismissSearchController(searchController: UISearchController) {
        
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        // Strips out all the leading and trailing spaces.
        let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
        let strippedString = searchController.searchBar.text!.stringByTrimmingCharactersInSet(whitespaceCharacterSet)
        self.resultsController.search(strippedString)
    }
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        
        // Encode the view state so it can be restored later.
        
        // Encode the title.
        coder.encodeObject(navigationItem.title!, forKey:RestorationKeys.viewControllerTitle.rawValue)
        
        // Encode the search controller's active state.
        coder.encodeBool(searchController.active, forKey:RestorationKeys.searchControllerIsActive.rawValue)
        
        // Encode the first responser status.
        coder.encodeBool(searchController.searchBar.isFirstResponder(), forKey:RestorationKeys.searchBarIsFirstResponder.rawValue)
        
        // Encode the search bar text.
        coder.encodeObject(searchController.searchBar.text, forKey:RestorationKeys.searchBarText.rawValue)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
        
        // Restore the title.
        guard let decodedTitle = coder.decodeObjectForKey(RestorationKeys.viewControllerTitle.rawValue) as? String else {
            fatalError("A title did not exist. In your app, handle this gracefully.")
        }
        title = decodedTitle
        
        // Restore the active state:
        // We can't make the searchController active here since it's not part of the view
        // hierarchy yet, instead we do it in viewWillAppear.
        //
        restoredState.wasActive = coder.decodeBoolForKey(RestorationKeys.searchControllerIsActive.rawValue)
        
        // Restore the first responder status:
        // Like above, we can't make the searchController first responder here since it's not part of the view
        // hierarchy yet, instead we do it in viewWillAppear.
        //
        restoredState.wasFirstResponder = coder.decodeBoolForKey(RestorationKeys.searchBarIsFirstResponder.rawValue)
        
        // Restore the text in the search field.
        searchController.searchBar.text = coder.decodeObjectForKey(RestorationKeys.searchBarText.rawValue) as? String
    }
}
