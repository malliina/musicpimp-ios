//
//  PlaylistParent.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PlaylistParent: ContainerParent {
    @IBOutlet var scopeSegment: UISegmentedControl!
    
    var dragButton: UIBarButtonItem?
    
    // non-nil if the playlist is server-loaded
    var savedPlaylist: SavedPlaylist? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let saveButton = PimpBarButton.system(.Save, target: self, onClick: self.savePlaylistAction)
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.savePlaylistAction))
        saveButton.style = UIBarButtonItemStyle.done
        let dragButton = PimpBarButton(title: "Edit", style: .plain, onClick: self.dragButtonClicked)
//        let loadPlaylistButton = PimpBarButton.system(.Bookmarks, target: self, onClick: self.loadPlaylistClicked)
        let loadPlaylistButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(self.loadPlaylistClicked(_:)))
        self.navigationItem.leftBarButtonItems = [ loadPlaylistButton, dragButton ]
        self.dragButton = dragButton
        // the first element in the array is right-most
        self.navigationItem.rightBarButtonItems = [ saveButton ]
        navigationItem.title = "PLAYLIST"
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: PimpColors.titleFont
        ]
        initScope(scopeSegment)
    }
    
    fileprivate func initScope(_ ctrl: UISegmentedControl) {
        ctrl.addTarget(self, action: #selector(self.scopeChanged(_:)), for: UIControlEvents.valueChanged)
    }
    
    func scopeChanged(_ ctrl: UISegmentedControl) {
        if let pc = findPlaylist() {
            let mode = ListMode(rawValue: ctrl.selectedSegmentIndex) ?? .playlist
            dragButton?.isEnabled = mode == .playlist
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
        let title = "Save Playlist"
        let message = playlist.name
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        let saveAction = UIAlertAction(title: "Save Current", style: UIAlertActionStyle.default) { (a) -> Void in
            self.savePlaylist(playlist)
        }
        let newAction = UIAlertAction(title: "Create New", style: UIAlertActionStyle.default) { (a) -> Void in
            self.newPlaylistAction()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (a) -> Void in
            
        }
        sheet.addAction(saveAction)
        sheet.addAction(newAction)
        sheet.addAction(cancelAction)
        self.present(sheet, animated: true, completion: nil)
    }
    
    func newPlaylistAction() {
        if let storyboard = self.storyboard {
            let vc = storyboard.instantiateViewController(withIdentifier: "SavePlaylist")
            vc.modalTransitionStyle = UIModalTransitionStyle.coverVertical
            if let spvc = vc as? SavePlaylistViewController, let playlist = savedPlaylist {
                spvc.name = playlist.name
            }
            //            self.navigationController?.pushViewController(vc, animated: true)
            let navController = UINavigationController(rootViewController: vc)
            self.present(navController, animated: true, completion: nil)
        } else {
            Log.error("No storyboard, cannot open save playlist ViewController")
        }
    }
    
    fileprivate func savePlaylist(_ playlist: SavedPlaylist) {
        library.savePlaylist(playlist, onError: Util.onError) { (id: PlaylistID) -> Void in
            self.savedPlaylist = SavedPlaylist(id: id, name: playlist.name, tracks: playlist.tracks)
            Log.info("Saved playlist with name \(playlist.name) and ID \(id.id)")
        }
    }
    
    @IBAction func unwindToPlaylist(_ sender: UIStoryboardSegue) {
        // returns from a "new playlist" screen
        if let source = sender.source as? SavePlaylistViewController, let name = source.name, let playlist = findPlaylist() {
            let playlist = SavedPlaylist(id: nil, name: name, tracks: playlist.tracks)
            savePlaylist(playlist)
        } else {
            Log.error("Unable to save playlist")
        }
    }
}
