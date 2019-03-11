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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "REPEAT"
        registerCell(reuseIdentifier: cellIdentifier)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let row = indexPath.row
        let dayName = weekDayName(row)
        let accessory = isChecked(row) ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
        if let label = cell.textLabel {
            label.text = "Every \(dayName)"
            label.textColor = PimpColors.shared.titles
        }
        cell.accessoryType = accessory
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) {
            let wasChecked = cell.accessoryType == .checkmark
            let newAccessory = wasChecked ? UITableViewCell.AccessoryType.none : UITableViewCell.AccessoryType.checkmark
            let willBeEnabled = !wasChecked
            if let day = dayForIndex(indexPath.row), let alarm = alarm {
                if willBeEnabled {
                    alarm.when.days.append(day)
                } else {
                    alarm.when.days.removeAll { $0 == day }
                }
            }
            cell.accessoryType = newAccessory
        }
    }
    
    func isChecked(_ row: Int) -> Bool {
        let day = dayForIndex(row)
        if let day = day, let days = alarm?.when.days {
            return days.contains(day)
        } else {
            return false
        }
    }
    
    func weekDayName(_ day: Int) -> String {
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
    
    func dayForIndex(_ day: Int) -> Day? {
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
}
