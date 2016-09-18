//
//  LibraryParent.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 13/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class LibraryParent: ContainerParent {
    var folder: MusicItem? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let title = (folder?.title ?? "Music")
        navigationItem.title = title
//        navigationController?.navigationBar.titleTextAttributes = [
//            NSFontAttributeName: PimpColors.titleFont
//        ]
//        navigationItem.rightBarButtonItem = PimpBarButton(title: "Test", style: .Plain, onClick: refreshClicked)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? LibraryController {
            destination.selected = folder
        }
    }
    
    func loadRoot() {
        let table: LibraryController? = findChild()
        if let table = table {
            table.loadRoot()
        } else {
            Log.error("Unable to find library table")
        }
    }
    
    func refreshClicked(_ sender: UIBarButtonItem) {
        Log.info("Item clicked")
    }
}
