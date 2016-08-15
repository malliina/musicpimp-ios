//
//  LibraryNavController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 21/06/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class LibraryNavController: UINavigationController {
    
    @IBOutlet var libraryTabBarItem: UITabBarItem!
    
    var libraryManager: LibraryManager { return LibraryManager.sharedInstance }
    var playerManager: PlayerManager { return PlayerManager.sharedInstance }
    var library: LibraryType { return libraryManager.active }
    var player: PlayerType { return playerManager.active }
    
    var libraryListener: Disposable? = nil
    var contentListener: Disposable? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        libraryListener = libraryManager.libraryChanged.addHandler(self) { (ivc) -> LibraryType -> () in
            ivc.onLibraryChanged
        }
        resetContentListener()
    }
    
    func resetContentListener() {
        contentListener?.dispose()
        contentListener = library.contentsUpdated.addHandler(self, handler: { (lm) -> MusicFolder? -> () in
            lm.onContentsUpdated
        })
    }
    
    func onLibraryChanged(newLibrary: LibraryType) {
        Log.info("Library changed")
        Util.onUiThread {
            self.pop()
        }
        resetContentListener()
    }
    
    func onContentsUpdated(m: MusicFolder?) {
        Log.info("Contents updated")
        Util.onUiThread {
            self.pop()
        }
    }
    
    func pop(animated: Bool = false) {
        self.popToRootViewControllerAnimated(animated)
        let children = childViewControllers
//        Log.info("Children: \(children.count)")
        if children.count == 1 {
            if let libraryController = children.headOption() as? LibraryParent {
                libraryController.loadRoot()
            }
        }
    }
}