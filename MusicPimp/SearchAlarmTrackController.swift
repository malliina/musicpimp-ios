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
        renderTable("Search for a track") {
            self.tableView.tableHeaderView = self.searchController.searchBar
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.isActive = true
    }
    
    override func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = itemAt(tableView, indexPath: indexPath), let track = item as? Track {
            alarm?.track = track
        }
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
        goBack()
    }

    func goBack() {
        let isAddMode = presentingViewController is UINavigationController
        if isAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController!.popViewController(animated: true)
        }
    }
}
