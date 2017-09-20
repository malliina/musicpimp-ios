//
// Created by Michael Skogberg on 01/05/2017.
// Copyright (c) 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class LibraryContainer: ContainerParent {
    var folder: Folder? = nil
    let tableVc = LibraryController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = (folder?.title.uppercased() ?? "MUSIC")
        initLibrary()
    }
    
    func initLibrary() {
        tableVc.selected = folder
        initChild(tableVc)
        tableVc.view.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(view)
            make.bottom.equalTo(playbackFooter.snp.top)
        }
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
