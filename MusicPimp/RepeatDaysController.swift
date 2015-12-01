//
//  RepeatDaysController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 30/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class RepeatDaysController: BaseTableController {
    let cellIdentifier = "RepeatDayCell"
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        let dayName = weekDayName(indexPath.row)
        cell.textLabel?.text = "Every \(dayName)"
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        Log.info("Did select")
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            let isChecked = cell.accessoryType == UITableViewCellAccessoryType.Checkmark
            let newAccessory = isChecked ? UITableViewCellAccessoryType.None : UITableViewCellAccessoryType.Checkmark
            cell.accessoryType = newAccessory
        }
    }
    
    func weekDayName(day: Int) -> String {
        switch day {
        case 0: return "Monday"
        case 1: return "Tuesday"
        case 2: return "Wednesday"
        case 3: return "Thursday"
        case 4: return "Friday"
        case 5: return "Saturday"
        case 6: return "Sunday"
        default: return "DOOMSDAY"
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
}
