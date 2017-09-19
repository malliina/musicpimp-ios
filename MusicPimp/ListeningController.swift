//
//  ListeningController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 06/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class ListeningController: PimpViewController, PlaybackEventDelegate, LibraryDelegate {
    var loadedListeners: [Disposable] = []
    var appearedListeners: [Disposable] = []
    
    var playerManager: PlayerManager { return PlayerManager.sharedInstance }
    var player: PlayerType { return playerManager.active }
    
    var libraryManager: LibraryManager { return LibraryManager.sharedInstance }
    var library: LibraryType { return libraryManager.active }
    
    let listener = PlaybackListener()
    let libraryListener = LibraryListener()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listener.playbacks = self
        libraryListener.delegate = self
        let _ = libraryManager.libraryChanged.addHandler(self) { (ivc) -> (LibraryType) -> () in
            ivc.onLibraryChanged
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listener.subscribe()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        listener.unsubscribe()
    }
    
    func onTrackChanged(_ track: Track?) {
        if let track = track {
            updateMedia(track)
        } else {
            updateNoMedia()
        }
    }
    
    func updateMedia(_ track: Track) {
        
    }
    
    func updateNoMedia() {
        
    }
    
    func onTimeUpdated(_ position: Duration) {
        
    }
    
    func onStateChanged(_ state: PlaybackState) {
        
    }
    
    func onLibraryChanged(to newLibrary: LibraryType) {
        
    }
}
