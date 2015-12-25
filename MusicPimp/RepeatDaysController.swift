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
    
    var alarm: MutableAlarm? = nil
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        let row = indexPath.row
        let dayName = weekDayName(row)
        let accessory = isChecked(row) ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
        cell.textLabel?.text = "Every \(dayName)"
        cell.accessoryType = accessory
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            let wasChecked = cell.accessoryType == UITableViewCellAccessoryType.Checkmark
            let newAccessory = wasChecked ? UITableViewCellAccessoryType.None : UITableViewCellAccessoryType.Checkmark
            let willBeEnabled = !wasChecked
            if let day = dayForIndex(indexPath.row), alarm = alarm {
                if willBeEnabled {
                    alarm.when.days.insert(day)
                } else {
                    alarm.when.days.remove(day)
                }
            }
            cell.accessoryType = newAccessory
        }
    }
    
    func isChecked(row: Int) -> Bool {
        let day = dayForIndex(row)
        if let day = day, days = alarm?.when.days {
            return days.contains(day)
        } else {
            return false
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
    
    func dayForIndex(day: Int) -> Day? {
        switch day {
        case 0: return Day.Mon
        case 1: return Day.Tue
        case 2: return Day.Wed
        case 3: return Day.Thu
        case 4: return Day.Fri
        case 5: return Day.Sat
        case 6: return Day.Sun
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
}
