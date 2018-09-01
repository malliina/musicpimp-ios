//
//  PlayQueueController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class PlayQueueController: BaseMusicController, PlaylistEventDelegate, SavePlaylistDelegate, PlaylistSelectDelegate {
    private let log = LoggerFactory.shared.vc(PlayQueueController.self)
    let defaultCellKey = "PimpMusicItemCell"
    
    private var current: Playlist = Playlist.empty
    private var tracks: [Track] { get { return current.tracks } }
    var emptyMessage: String { get { return "The playlist is empty." } }
    override var musicItems: [MusicItem] { return tracks }
    let listener = PlaybackListener()
    
    // non-nil if the playlist is server-loaded
    var savedPlaylist: SavedPlaylist? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(SnapMusicCell.self, forCellReuseIdentifier: defaultCellKey)
        initNavbar()
        listener.playlists = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listener.subscribe()
        let state = player.current()
        let currentPlaylist = Playlist(tracks: state.playlist, index: state.playlistIndex)
        onNewPlaylist(currentPlaylist)
        let downloadDisposable = DownloadUpdater.instance.progress.subscribe(onNext: { (progress) in
            self.onProgress(track: progress)
        })
        listeners = [downloadDisposable]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener.unsubscribe()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let cell: SnapMusicCell = loadCell(defaultCellKey, index: indexPath)
        cell.accessoryDelegate = self
        // crash w/ index out of range - I think this is now fixed
        let track = tracks[index]
        cell.title.text = track.title
        paintTrackCell(cell: cell, track: track, isHighlight: index == current.index, downloadState: DownloadUpdater.instance.progressFor(track: track))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        limitChecked {
            _ = self.player.skip(index)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let index = indexPath.row
        tableView.reloadRows(at: [indexPath], with: .none)
        _ = limitChecked {
            self.player.playlist.removeIndex(index)
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceRow = sourceIndexPath.row
        let destinationRow = destinationIndexPath.row
        let newTracks = Arrays.move(sourceRow, destIndex: destinationRow, xs: current.tracks)
        let newIndex = computeNewIndex(sourceRow, dest: destinationRow)
        current = Playlist(tracks: newTracks, index: newIndex)
        _ = player.playlist.move(sourceRow, dest: destinationRow)
    }
    
    func computeNewIndex(_ src: Int, dest: Int) -> Int? {
        if let index = current.index {
            return LocalPlaylist.newPlaylistIndex(index, src: src, dest: dest)
        }
        return nil
    }
    
    func initNavbar() {
        navigationItem.title = "PLAYLIST"
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(loadPlaylistClicked(_:))),
            UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(dragClicked(_:)))
        ]
        // the first element in the array is right-most
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(savePlaylistClicked(_:)))
        ]
    }
    
    @objc func loadPlaylistClicked(_ button: UIBarButtonItem) {
        let dest = SavedPlaylistsTableViewController()
        dest.delegate = self
        dest.modalPresentationStyle = .fullScreen
        dest.modalTransitionStyle = .coverVertical
        let nav = UINavigationController(rootViewController: dest)
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func savePlaylistClicked(_ item: UIBarButtonItem) {
        if let playlist = savedPlaylist {
            // opens actions drop-up: does the user want to save the existing playlist or create a new one?
            displayActionsForPlaylist(SavedPlaylist(id: playlist.id, name: playlist.name, trackCount: playlist.trackCount, tracks: tracks))
        } else {
            // goes directly to the "new playlist" view controller
            newPlaylistAction()
        }
    }
    
    func displayActionsForPlaylist(_ playlist: SavedPlaylist) {
        let message = playlist.name
        let sheet = UIAlertController(title: "Save Playlist", message: message, preferredStyle: .actionSheet)
        let saveAction = UIAlertAction(title: "Save Current", style: .default) { (a) -> Void in
            self.savePlaylist(playlist)
        }
        let newAction = UIAlertAction(title: "Create New", style: .default) { (a) -> Void in
            self.newPlaylistAction()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (a) -> Void in

        }
        sheet.addAction(saveAction)
        sheet.addAction(newAction)
        sheet.addAction(cancelAction)
        self.present(sheet, animated: true, completion: nil)
    }
    
    func newPlaylistAction() {
        let vc = SavePlaylistViewController()
        vc.modalTransitionStyle = .coverVertical
        if let playlist = savedPlaylist {
            vc.name = playlist.name
        }
        vc.tracks = tracks
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
    }
    
    func onIndexChanged(to index: Int?) {
        onUiThread {
            self.current = Playlist(tracks: self.current.tracks, index: index)
            self.clearFeedback()
            self.tableView.reloadData()
        }
    }
    
    func onNewPlaylist(_ playlist: Playlist) {
        onUiThread {
            self.current = playlist
            self.reloadTable(feedback: self.tracks.count == 0 ? self.emptyMessage : nil)
        }
    }
    
    func withReload(_ code: @escaping () -> Void) {
        onUiThread {
            code()
            self.reloadTable(feedback: self.tracks.count == 0 ? self.emptyMessage : nil)
        }
    }
    
    @objc func dragClicked(_ dragButton: UIBarButtonItem) {
        let isEditing = self.tableView.isEditing
        self.tableView.setEditing(!isEditing, animated: true)
        let title = isEditing ? "Edit" : "Done"
        dragButton.style = isEditing ? .plain : .done
        dragButton.title = title
    }
    
    fileprivate func savePlaylist(_ playlist: SavedPlaylist) {
        run(LibraryManager.sharedInstance.active.savePlaylist(playlist)) { id in
            self.log.info("Saved playlist \(id.id) with name \(playlist.name) and \(playlist.tracks.count) tracks")
            self.savedPlaylist = playlist
        }
    }
    
    func onPlaylistSaved(saved: SavedPlaylist) {
        self.savedPlaylist = saved
    }

    func playlistActivated(_ playlist: SavedPlaylist) {
        self.savedPlaylist = playlist
    }
}

extension PlayQueueController {
    func onProgress(track: TrackProgress) {
        if let index = musicItems.indexOf({ (item: MusicItem) -> Bool in item.id == track.track.id }) {
            updateRows(row: index)
        }
    }
    
    private func updateRows(row: Int) {
        let itemIndexPath = IndexPath(row: row, section: 0)
        onUiThread {
            // The app crashed if reloading a row while concurrently dragging and dropping rows.
            // TODO investigate and fix, but as a workaround, we don't update the download progress when editing.
            if !self.tableView.isEditing && row < self.tracks.count {
                self.tableView.reloadRows(at: [itemIndexPath], with: .none)
            }
        }
    }
}
