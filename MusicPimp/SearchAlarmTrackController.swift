//
//  SelectAlarmTrackController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 25/12/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class SearchAlarmTrackController: SearchableMusicController {
    
    var alarm: MutableAlarm? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        renderTable("Search for a track")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        searchController.active = true
    }
    
    override func didPresentSearchController(searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let item = itemAt(tableView, indexPath: indexPath), track = item as? Track {
            alarm?.track = track
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        goBack()
    }

    func goBack() {
        let isAddMode = presentingViewController is UINavigationController
        if isAddMode {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            navigationController!.popViewControllerAnimated(true)
        }
    }
}
