//
//  PlaylistParent.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

fileprivate extension Selector {
    static let dragClicked = #selector(PlaylistParent.dragButtonClicked(_:))
    static let savePlaylist = #selector(PlaylistParent.savePlaylistAction(_:))
    static let loadPlaylist = #selector(PlaylistParent.loadPlaylistClicked(_:))
    static let scopeChanged = #selector(PlaylistParent.scopeChanged(_:))
}

class PlaylistParent: ContainerParent, SavePlaylistDelegate {
    let scopeSegment = UISegmentedControl(items: ["Current", "Popular", "Recent"])
    let table = PlaylistController()
    // non-nil if the playlist is server-loaded
    var savedPlaylist: SavedPlaylist? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: .loadPlaylist),
            UIBarButtonItem(title: "Edit", style: .plain, target: self, action: .dragClicked)
        ]
        // the first element in the array is right-most
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .save, target: self, action: .savePlaylist)
        ]
        initUI()
    }
    
    func initUI() {
        initScope(scopeSegment)
        addSubviews(views: [scopeSegment])
        scopeSegment.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        initChild(table)
        table.view.snp.makeConstraints { make in
            make.top.equalTo(scopeSegment.snp.bottom).offset(8)
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(playbackFooter.snp.top)
        }
    }
    
    fileprivate func initScope(_ ctrl: UISegmentedControl) {
        ctrl.selectedSegmentIndex = 0
        ctrl.addTarget(self, action: .scopeChanged, for: .valueChanged)
        ctrl.setTitleTextAttributes([NSForegroundColorAttributeName: PimpColors.tintColor], for: .normal)
    }
    
    override func onLibraryChanged(_ newLibrary: LibraryType) {
        scopeChanged(scopeSegment)
    }
    
    func scopeChanged(_ ctrl: UISegmentedControl) {
        if let pc = findPlaylist() {
            let mode = ListMode(rawValue: ctrl.selectedSegmentIndex) ?? .playlist
//            dragButton.isEnabled = mode == .playlist
            pc.maybeRefresh(mode)
        } else {
            Log.info("Unable to find embedded PlaylistController")
        }
    }
    
    func dragButtonClicked(_ button: UIBarButtonItem) {
        if let pc = findPlaylist() {
            pc.dragClicked(button)
        } else {
            Log.info("Cannot drag unable to find playlist table")
        }
    }
    
    func loadPlaylistClicked(_ button: UIBarButtonItem) {
        let dest = SavedPlaylistsTableViewController()
        dest.modalPresentationStyle = .fullScreen
        dest.modalTransitionStyle = .coverVertical
        let nav = UINavigationController(rootViewController: dest)
        self.present(nav, animated: true, completion: nil)
        //self.showViewController(dest, sender: self)
        //self.navigationController?.pushViewController(dest, animated: true)
    }
    
    func findPlaylist() -> PlaylistController? {
        return findChild()
    }
    
    func savePlaylistAction(_ item: UIBarButtonItem) {
        if let playlist = savedPlaylist {
            // opens actions drop-up: does the user want to save the existing playlist or create a new one?
            displayActionsForPlaylist(playlist)
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
        vc.tracks = table.tracks
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
    }
    
    func onPlaylistSaved(saved: SavedPlaylist) {
        self.savedPlaylist = saved
    }
    
    fileprivate func savePlaylist(_ playlist: SavedPlaylist) {
        LibraryManager.sharedInstance.active.savePlaylist(playlist, onError: Util.onError) { (id: PlaylistID) -> Void in
            Log.info("Saved playlist with name \(playlist.name) and ID \(id.id)")
        }
    }
}
