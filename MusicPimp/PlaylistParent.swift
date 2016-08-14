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
        let saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(self.savePlaylistAction))
        saveButton.style = UIBarButtonItemStyle.Done
        let dragButton = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: #selector(self.dragButtonClicked(_:)))
        let loadPlaylistButton = UIBarButtonItem(barButtonSystemItem: .Bookmarks, target: self, action: #selector(self.loadPlaylistClicked(_:)))
        self.navigationItem.leftBarButtonItems = [ loadPlaylistButton, dragButton ]
        self.dragButton = dragButton
        // the first element in the array is right-most
        self.navigationItem.rightBarButtonItems = [ saveButton ]
        initScope(scopeSegment)
    }
    
    private func initScope(ctrl: UISegmentedControl) {
        ctrl.addTarget(self, action: #selector(self.scopeChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
    }
    
    func scopeChanged(ctrl: UISegmentedControl) {
        if let pc = findPlaylist() {
            let mode = ListMode(rawValue: ctrl.selectedSegmentIndex) ?? .Playlist
            dragButton?.enabled = mode == .Playlist
            pc.maybeRefresh(mode)
        } else {
            Log.info("Unable to find embedded PlaylistController")
        }
    }
    
    func dragButtonClicked(button: UIBarButtonItem) {
        if let pc = findPlaylist() {
            pc.dragClicked(button)
        } else {
            Log.info("Cannot drag unable to find playlist table")
        }
    }
    
    func loadPlaylistClicked(button: UIBarButtonItem) {
        let dest = SavedPlaylistsTableViewController()
        dest.modalPresentationStyle = .FullScreen
        dest.modalTransitionStyle = .CoverVertical
        let nav = UINavigationController(rootViewController: dest)
        self.presentViewController(nav, animated: true, completion: nil)
        //self.showViewController(dest, sender: self)
        //self.navigationController?.pushViewController(dest, animated: true)
    }
    
    func findPlaylist() -> PlaylistController? {
        return findChild()
    }
    
    func savePlaylistAction() {
        if let playlist = savedPlaylist {
            // opens actions drop-up: does the user want to save the existing playlist or create a new one?
            displayActionsForPlaylist(playlist)
        } else {
            // goes directly to the "new playlist" view controller
            newPlaylistAction()
        }
    }
    
    func displayActionsForPlaylist(playlist: SavedPlaylist) {
        let title = "Save Playlist"
        let message = playlist.name
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let saveAction = UIAlertAction(title: "Save Current", style: UIAlertActionStyle.Default) { (a) -> Void in
            self.savePlaylist(playlist)
        }
        let newAction = UIAlertAction(title: "Create New", style: UIAlertActionStyle.Default) { (a) -> Void in
            self.newPlaylistAction()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (a) -> Void in
            
        }
        sheet.addAction(saveAction)
        sheet.addAction(newAction)
        sheet.addAction(cancelAction)
        self.presentViewController(sheet, animated: true, completion: nil)
    }
    
    func newPlaylistAction() {
        if let storyboard = self.storyboard {
            let vc = storyboard.instantiateViewControllerWithIdentifier("SavePlaylist")
            vc.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
            if let spvc = vc as? SavePlaylistViewController, playlist = savedPlaylist {
                spvc.name = playlist.name
            }
            //            self.navigationController?.pushViewController(vc, animated: true)
            let navController = UINavigationController(rootViewController: vc)
            self.presentViewController(navController, animated: true, completion: nil)
        } else {
            Log.error("No storyboard, cannot open save playlist ViewController")
        }
    }
    
    private func savePlaylist(playlist: SavedPlaylist) {
        library.savePlaylist(playlist, onError: Util.onError) { (id: PlaylistID) -> Void in
            self.savedPlaylist = SavedPlaylist(id: id, name: playlist.name, tracks: playlist.tracks)
            Log.info("Saved playlist with name \(playlist.name) and ID \(id.id)")
        }
    }
    
    @IBAction func unwindToPlaylist(sender: UIStoryboardSegue) {
        // returns from a "new playlist" screen
        if let source = sender.sourceViewController as? SavePlaylistViewController, name = source.name, playlist = findPlaylist() {
            let playlist = SavedPlaylist(id: nil, name: name, tracks: playlist.tracks)
            savePlaylist(playlist)
        } else {
            Log.error("Unable to save playlist")
        }
    }
}
