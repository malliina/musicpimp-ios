//
//  AlarmsController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class AlarmsController : PimpTableController {
    let endpointSection = 0
    let notificationSection = 1
    let alarmsSection = 2
    
    let endpointIdentifier = "EndpointCell"
    let pushEnabledIdentifier = "PushEnabledCell"
    let alarmIdentifier = "AlarmCell"
    let alarmCellKey = "MainSubCell"
    
    let noAlarmsMessage = "No saved alarms"
    
    var endpoint: Endpoint? = nil
    var pushEnabled: Bool = false
    var alarms: [Alarm] = []
    var feedbackMessage: String? = nil
    
    var pushSwitch: UISwitch? = nil
    
    var isEndpointValid: Bool { return endpoint != nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNib(alarmCellKey)
        reloadAlarms()
        // TODO create custom UISwitch with toggle handler
        let onOff = PimpSwitch { (uiSwitch) in
            self.didToggleNotifications(uiSwitch)
        }
        pushSwitch = onOff
        settings.defaultAlarmEndpointChanged.addHandler(self) { (ac) -> Endpoint -> () in
            ac.didChangeDefaultAlarmEndpoint
        }
    }
    
    func didChangeDefaultAlarmEndpoint(e: Endpoint) {
        reloadAlarms()
    }
    
    func didToggleNotifications(uiSwitch: UISwitch) {
        let isOn = uiSwitch.on
        if let endpoint = endpoint {
            let toggleRegistration = isOn ? registerNotifications : unregisterNotifications
            toggleRegistration(endpoint) {
                self.settings.saveNotificationsEnabled(endpoint, enabled: isOn)
            }
        }
    }
    
    func registerNotifications(endpoint: Endpoint, onSuccess: () -> Void) {
        let alarmLibrary = Libraries.fromEndpoint(endpoint)
        if let token = settings.pushToken {
            alarmLibrary.registerNotifications(token, tag: endpoint.id, onError: onError, onSuccess: onSuccess)
        }
    }
    
    func unregisterNotifications(endpoint: Endpoint, onSuccess: () -> Void) {
        let alarmLibrary = Libraries.fromEndpoint(endpoint)
        alarmLibrary.unregisterNotifications(endpoint.id, onError: onError, onSuccess: onSuccess)
    }
    
    func reloadAlarms() {
        feedbackMessage = "Loading alarms..."
        endpoint = settings.defaultNotificationEndpoint()
        if let endpoint = endpoint {
            loadAlarms(endpoint)
        } else {
            feedbackMessage = "Please configure a MusicPimp endpoint to continue."
        }
    }
    
    func loadAlarms(endpoint: Endpoint) {
        loadAlarms(Libraries.fromEndpoint(endpoint))
    }
    
    func loadAlarms(library: LibraryType) {
        library.alarms(onAlarmError, f: onAlarms)
    }
    
    func saveAndReload(alarm: Alarm) {
        if let endpoint = endpoint {
            let library = Libraries.fromEndpoint(endpoint)
            library.saveAlarm(alarm, onError: onError) {
                self.loadAlarms(library)
            }
        }
    }
    
    func onAlarms(alarms: [Alarm]) {
        feedbackMessage = nil
        self.alarms = alarms
        renderTable()
    }
    
    func onAlarmError(error: PimpError) {
        let message = PimpError.stringify(error)
        feedbackMessage = message
        renderTable()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Max one because we display feedback to the user if the table is empty
        if section == alarmsSection {
            return max(alarms.count, 1)
        }
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case endpointSection:
            let cell = tableView.dequeueReusableCellWithIdentifier(endpointIdentifier, forIndexPath: indexPath)
            cell.detailTextLabel?.text = endpoint?.name ?? "None"
            cell.textLabel?.enabled = isEndpointValid
            return cell
        case notificationSection:
            let cell = tableView.dequeueReusableCellWithIdentifier(pushEnabledIdentifier, forIndexPath: indexPath)
            cell.accessoryView = pushSwitch
            if let endpoint = endpoint {
                pushSwitch?.on = settings.notificationsEnabled(endpoint)
            }
            let isNotificationsToggleEnabled = isEndpointValid && settings.notificationsAllowed
            cell.textLabel?.enabled = isNotificationsToggleEnabled
            pushSwitch?.enabled = isNotificationsToggleEnabled
            return cell
        case alarmsSection:
            if alarms.count == 0 {
                return feedbackCellWithText(tableView, indexPath: indexPath, text: feedbackMessage ?? noAlarmsMessage)
            } else {
                let item = alarms[indexPath.row]
                let alarmCell: MainSubCell = loadCell(alarmCellKey, index: indexPath)
                let when = item.when
                alarmCell.mainTitle.text = item.track.title + " at " + when.time.formatted()
                alarmCell.subtitle.text = Day.describeDays(when.days)
                let uiSwitch = PimpSwitch { (uiSwitch) in
                    self.onAlarmOnOffToggled(item, uiSwitch: uiSwitch)
                }
                uiSwitch.on = item.enabled
                alarmCell.accessoryView = uiSwitch
                return alarmCell
            }
        default:
            // We never get here
            return tableView.dequeueReusableCellWithIdentifier(BaseMusicController.feedbackIdentifier, forIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == alarmsSection {
            return FeedbackTable.mainAndSubtitleCellHeight
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case endpointSection:
            return "MusicPimp servers support scheduled playback of music."
        case notificationSection:
            return "MusicPimp sends a notification to this device when scheduled playback starts, so that you can easily silence it."
        default:
            return ""
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        if indexPath.section == alarmsSection {
            if let alarm = alarms.get(row),
                endpoint = endpoint,
                storyboard = storyboard,
                dest = storyboard.instantiateViewControllerWithIdentifier("EditAlarm") as? EditAlarmTableViewController {
                dest.initEditAlarm(alarm, endpoint: endpoint)
                self.navigationController?.pushViewController(dest, animated: true)
            } else {
                Log.error("No alarm, endpoint, storyboard or destination")
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return isEndpointValid
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let index = indexPath.row
        let alarm = alarms[index]
        if let id = alarm.id {
            library.deleteAlarm(id, onError: onError) {
                self.alarms.removeAtIndex(index)
                self.renderTable()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let segueDestination = segue.destinationViewController
        if let endpoint = endpoint {
            if let dest = segueDestination as? EditAlarmTableViewController {
                if let row = self.tableView.indexPathForSelectedRow {
                    let index = row.item
                    if let alarm = alarms.get(index) {
                        dest.initEditAlarm(alarm, endpoint: endpoint)
                    } else {
                        Log.error("Tried to edit non-existing alarm at index \(index)")
                    }
                } else {
                    dest.initNewAlarm(endpoint)
                }
            } else if let dest = segueDestination as? UINavigationController {
                if let actualDestination = dest.topViewController as? EditAlarmTableViewController {
                    actualDestination.initNewAlarm(endpoint)
                } else {
                    Log.error("Unexpected destination \(segue.destinationViewController)")
                }
            }
        } else {
            Log.error("Cannot configure alarms without a valid playback device")
        }
    }
    
    @IBAction func unwindToAlarms(sender: UIStoryboardSegue) {
        if let source = sender.sourceViewController as? EditAlarmTableViewController,
            alarm = source.mutableAlarm?.toImmutable() {
            saveAndReload(alarm)
        }
    }
    
    func onAlarmOnOffToggled(alarm: Alarm, uiSwitch: UISwitch) {
        let isEnabled = uiSwitch.on
        info("Toggled switch, is on: \(isEnabled) for \(alarm.track.title)")
        let mutable = MutableAlarm(a: alarm)
        mutable.enabled = isEnabled
        if let updated = mutable.toImmutable() {
            saveAndReload(updated)
        }
    }
    
}
