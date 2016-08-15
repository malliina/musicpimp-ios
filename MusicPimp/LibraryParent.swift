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
        if let folder = folder {
            navigationItem.title = folder.title
        }
        navigationItem.rightBarButtonItem = PimpBarButton(title: "Test", style: .Plain, onClick: refreshClicked)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? LibraryController {
            destination.selected = folder
        }
    }
    
    func refreshClicked(sender: UIBarButtonItem) {
        Log.info("Item clicked")
    }
}
