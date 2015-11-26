//
//  AlarmsController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class AlarmsController : PimpTableController {
    
    var alarms: [Alarm] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: PimpTableController.feedbackIdentifier)
        feedbackMessage = "Loading alarms..."
        loadAlarms()
    }
    
    func loadAlarms() {
        library.alarms(onLoadError, f: onAlarms)
    }
    
    func onAlarms(alarms: [Alarm]) {
        feedbackMessage = nil
        self.alarms = alarms
        renderTable()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Max one because we display feedback to the user if the table is empty
        return max(alarms.count, 1)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if alarms.count == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(BaseMusicController.feedbackIdentifier, forIndexPath: indexPath)
            let statusMessage = feedbackMessage ?? "No saved alarms"
            cell.textLabel?.text = statusMessage
            return cell
        } else {
            let item = alarms[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("AlarmCell", forIndexPath: indexPath)
            cell.textLabel?.text = item.track.title
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let index = indexPath.row
        let alarm = alarms[index]
        if let id = alarm.id {
            library.deleteAlarm(id, onError: onError) {
                Log.info("Deleted alarm with ID \(id)")
                self.alarms.removeAtIndex(index)
                self.renderTable()
            }
        }
    }
}
