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
        searchController.active = true
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(BaseMusicController.feedbackIdentifier, forIndexPath: indexPath)
        if let label = cell.textLabel {
            label.lineBreakMode = NSLineBreakMode.ByWordWrapping
            label.numberOfLines = 0
            let statusMessage = feedbackMessage ?? "Search for a track"
            label.text = statusMessage
        }
        return cell
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
