//
//  EditAlarmTableViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 30/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class EditAlarmTableViewController: BaseTableController {
    let timePickerIdentifier = "TimePickerCell"
    let repeatIdentifier = "RepeatCell"
    let trackIdentifier = "TrackCell"
    let playIdentifier = "PlayCell"
    let deleteAlarmIdentifier = "DeleteCell"
    
    var libraryManager: LibraryManager { return LibraryManager.sharedInstance }
    var playerManager: PlayerManager { return PlayerManager.sharedInstance }
    
    var mutableAlarm: MutableAlarm? = nil
    var endpoint: Endpoint? = nil
    
    func initAlarm(alarm: Alarm, endpoint: Endpoint) {
        self.mutableAlarm = MutableAlarm(a: alarm)
        self.endpoint = endpoint
    }
    
    @IBOutlet var saveButton: UIBarButtonItem!
    
    @IBOutlet var datePicker: UIDatePicker!
  
    func clockTime(date: NSDate) -> ClockTime {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Hour, .Minute], fromDate: date)
        return ClockTime(hour: components.hour, minute: components.minute)
    }
    
    func updateDate() {
        if let mutableAlarm = mutableAlarm {
            let time = ClockTime(date: datePicker.date)
            let when = mutableAlarm.when
            when.hour = time.hour
            when.minute = time.minute
        }
    }
    
    // adapted from http://stackoverflow.com/a/12741639
    func changeDate(datePicker: UIDatePicker, time: ClockTime) {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: datePicker.date)
        components.calendar = calendar // wtf
        components.hour = time.hour
        components.minute = time.minute
        if let date = components.date {
            datePicker.date = date
        }
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        goBack()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.mutableAlarm == nil {
            self.mutableAlarm = MutableAlarm()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        renderTable()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if saveButton === sender {
            updateDate()
        }
        if let destination = segue.destinationViewController as? RepeatDaysController {
            destination.alarm = self.mutableAlarm
        }
        if let trackDestination = segue.destinationViewController as? SearchAlarmTrackController {
            trackDestination.alarm = self.mutableAlarm
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let reuseIdentifier = cell.reuseIdentifier {
            switch reuseIdentifier {
            case timePickerIdentifier:
                if let time = mutableAlarm?.when {
                    changeDate(datePicker, time: ClockTime(hour: time.hour, minute: time.minute))
                }
                break
            case repeatIdentifier:
                let emptyDays = Set<Day>()
                let activeDays = mutableAlarm?.when.days ?? emptyDays
                cell.detailTextLabel?.text = describeDays(activeDays)
                break
            case trackIdentifier:
                cell.detailTextLabel?.text = mutableAlarm?.track?.title ?? "No track"
                break
            case playIdentifier:
                cell.textLabel?.enabled = mutableAlarm?.track != nil
                break
            case deleteAlarmIdentifier:
                cell.textLabel?.enabled = mutableAlarm?.id != nil
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                break
            default:
                break
            }
        }
        return cell
    }
    
    func describeDays(days: Set<Day>) -> String {
        if days.isEmpty {
            return "Never"
        }
        if days.count == 7 {
            return "Every day"
        }
        if days == [Day.Sat, Day.Sun] {
            return "Weekends"
        }
        if days == [Day.Mon, Day.Tue, Day.Wed, Day.Thu, Day.Fri] {
            return "Weekdays"
        }
        return days.sort { (f, s) -> Bool in
            return Day.index(f) < Day.index(s)
        }.mkString(" ")
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let identifier = tableView.cellForRowAtIndexPath(indexPath)?.reuseIdentifier {
            switch identifier {
            case deleteAlarmIdentifier:
                if let alarmId = mutableAlarm?.id, endpoint = endpoint {
                    tableView.deselectRowAtIndexPath(indexPath, animated: false)
                    Libraries.fromEndpoint(endpoint).deleteAlarm(alarmId, onError: onError) {
                        Util.onUiThread {
                            self.goBack(true)
                        }
                    }
                }
                break
            case playIdentifier:
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                if let track = mutableAlarm?.track, endpoint = endpoint {
                    let player = Players.fromEndpoint(endpoint)
                    Players.fromEndpoint(endpoint).open({ () -> Void in
                        player.resetAndPlay(track)
                        player.close()
                        }, onError: onConnectError)
                }
                break
            default:
                break
            }
        }
    }
    
    func onConnectError(e: NSError) {
        
    }
    
    func goBack(didDelete: Bool = false) {
        let isAddMode = presentingViewController != nil
        if isAddMode {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            navigationController!.popViewControllerAnimated(true)
            if didDelete {
                if let alarmsController = navigationController!.viewControllers.last as? AlarmsController {
                    // reloads so that the deleted alarm entry disappears from the table we now return to
                    alarmsController.reloadAlarms()
                }
            }
        }
    }
}
