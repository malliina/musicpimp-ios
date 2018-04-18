//
// Created by Michael Skogberg on 01/05/2017.
// Copyright (c) 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class LibraryContainer: PlaybackContainer {
    private let log = LoggerFactory.shared.vc(LibraryContainer.self)
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
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        // https://stackoverflow.com/a/14155394
        let willPop = parent == nil
        if willPop {
            guard let library = child as? LibraryController else { return }
            library.stopListening()
            library.stopUpdates()
        }
    }
    
    override func onLibraryChanged(to newLibrary: LibraryType) {
        super.onLibraryChanged(to: newLibrary)
        pop()
    }
    
    private func pop(_ animated: Bool = false) {
        self.navigationController?.popToRootViewController(animated: animated)
        let children = childViewControllers
        if let libraryController = children.headOption() as? LibraryController {
            libraryController.loadRoot()
        }
    }
}
