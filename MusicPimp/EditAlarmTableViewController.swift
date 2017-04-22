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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.mutableAlarm == nil {
            self.mutableAlarm = MutableAlarm()
        }
        // hack
        datePicker.setValue(PimpColors.titles, forKey: "textColor")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        renderTable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        updateDate()
        super.viewWillDisappear(animated)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func initEditAlarm(_ alarm: Alarm, endpoint: Endpoint) {
        self.mutableAlarm = MutableAlarm(a: alarm)
        self.endpoint = endpoint
    }
    
    func initNewAlarm(_ endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    @IBOutlet var saveButton: UIBarButtonItem!
    
    @IBOutlet var datePicker: UIDatePicker!
  
    func clockTime(_ date: Date) -> ClockTime {
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.hour, .minute], from: date)
        return ClockTime(hour: components.hour!, minute: components.minute!)
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
    func changeDate(_ datePicker: UIDatePicker, time: ClockTime) {
        let components = time.dateComponents(datePicker.date)
        if let date = (components as NSDateComponents).date {
            datePicker.date = date
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        goBack()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let sender = sender as? UIBarButtonItem, saveButton === sender {
            updateDate()
        }
        let dest = segue.destination
        if let destination = dest as? RepeatDaysController {
            destination.alarm = self.mutableAlarm
        }
        if let trackDestination = dest as? SearchAlarmTrackController {
            trackDestination.alarm = self.mutableAlarm
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
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
                cell.detailTextLabel?.text = Day.describeDays(activeDays)
                break
            case trackIdentifier:
                cell.detailTextLabel?.text = mutableAlarm?.track?.title ?? "No track"
                break
            case playIdentifier:
                cell.textLabel?.isEnabled = mutableAlarm?.track != nil
                break
            case deleteAlarmIdentifier:
                cell.textLabel?.isEnabled = mutableAlarm?.id != nil
                cell.textLabel?.textColor = PimpColors.deletion
                cell.selectionStyle = UITableViewCellSelectionStyle.default
                break
            default:
                break
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let identifier = tableView.cellForRow(at: indexPath)?.reuseIdentifier {
            switch identifier {
            case deleteAlarmIdentifier:
                if let alarmId = mutableAlarm?.id, let endpoint = endpoint {
                    tableView.deselectRow(at: indexPath, animated: false)
                    Libraries.fromEndpoint(endpoint).deleteAlarm(alarmId, onError: onError) {
                        Util.onUiThread {
                            self.goBack(true)
                        }
                    }
                }
                break
            case playIdentifier:
                tableView.deselectRow(at: indexPath, animated: false)
                if let track = mutableAlarm?.track, let endpoint = endpoint {
                    let player = Players.fromEndpoint(endpoint)
                    player.open({ () -> Void in
                        let success = player.resetAndPlay(track)?.message ?? "success"
                        Log.info("Playing \(track.title): \(success)")
                        player.close()
                        }, onError: onConnectError)
                } else {
                    let desc = mutableAlarm?.track?.title ?? "no alarm or track"
                    Log.error("Cannot play track, \(desc)")
                }
                break
            default:
                break
            }
        }
    }
    
    func onConnectError(_ e: Error) {
        
    }
    
    func goBack(_ didDelete: Bool = false) {
        let isAddMode = presentingViewController != nil
        if isAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController!.popViewController(animated: true)
            if didDelete {
                if let alarmsController = navigationController!.viewControllers.last as? AlarmsController {
                    // reloads so that the deleted alarm entry disappears from the table we now return to
                    alarmsController.reloadAlarms()
                }
            }
        }
    }
}
