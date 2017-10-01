//
// Created by Michael Skogberg on 01/05/2017.
// Copyright (c) 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class LibraryContainer: PlaybackContainer {
    convenience init() {
        self.init(folder: nil)
    }
    
    convenience init(folder: Folder?) {
        let library = LibraryController()
        if let folder = folder {
            library.selected = folder
        }
        self.init(title: folder?.title.uppercased() ?? "MUSIC", child: library)
    }
    
    override func onLibraryChanged(to newLibrary: LibraryType) {
        super.onLibraryChanged(to: newLibrary)
        pop()
    }
    
    func pop(_ animated: Bool = false) {
        self.navigationController?.popToRootViewController(animated: animated)
        let children = childViewControllers
        if let libraryController = children.headOption() as? LibraryController {
            libraryController.loadRoot()
        }
    }
}
