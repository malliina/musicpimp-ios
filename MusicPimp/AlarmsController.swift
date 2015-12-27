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
    
    let noAlarmsMessage = "No saved alarms"
    
    var endpoint: Endpoint? = nil
    var pushEnabled: Bool = false
    var alarms: [Alarm] = []
    
    var pushSwitch: UISwitch? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: PimpTableController.feedbackIdentifier)
        reloadAlarms()
        // TODO create custom UISwitch with toggle handler
        let onOff = UISwitch(frame: CGRect.zero)
        onOff.addTarget(self, action: Selector("didToggleNotifications:"), forControlEvents: UIControlEvents.ValueChanged)
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
        
    }
    
    func unregisterNotifications(endpoint: Endpoint, onSuccess: () -> Void) {
        
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
        library.alarms(onLoadError, f: onAlarms)
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
            cell.textLabel?.enabled = endpoint != nil
            return cell
        case notificationSection:
            let cell = tableView.dequeueReusableCellWithIdentifier(pushEnabledIdentifier, forIndexPath: indexPath)
            cell.accessoryView = pushSwitch
            if let endpoint = endpoint {
                pushSwitch?.on = settings.notificationsEnabled(endpoint)
            }
            let isNotificationsToggleEnabled = endpoint != nil && settings.notificationsAllowed
            cell.textLabel?.enabled = isNotificationsToggleEnabled
            pushSwitch?.enabled = isNotificationsToggleEnabled
            return cell
        case alarmsSection:
            if alarms.count == 0 {
                let feedbackCell = tableView.dequeueReusableCellWithIdentifier(BaseMusicController.feedbackIdentifier, forIndexPath: indexPath)
                let statusMessage = feedbackMessage ?? noAlarmsMessage
                feedbackCell.textLabel?.text = statusMessage
                return feedbackCell
            } else {
                let item = alarms[indexPath.row]
                let alarmCell = tableView.dequeueReusableCellWithIdentifier(alarmIdentifier, forIndexPath: indexPath)
                alarmCell.textLabel?.text = item.track.title
                return alarmCell
            }
        default:
            // We never get here
            return tableView.dequeueReusableCellWithIdentifier(BaseMusicController.feedbackIdentifier, forIndexPath: indexPath)
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
        if let dest = segue.destinationViewController as? EditAlarmTableViewController,
            row = self.tableView.indexPathForSelectedRow,
            endpoint = endpoint {
            let alarm = alarms[row.item]
            dest.initAlarm(alarm, endpoint: endpoint)
        }
    }
    
    @IBAction func unwindToAlarms(sender: UIStoryboardSegue) {
        if let source = sender.sourceViewController as? EditAlarmTableViewController,
            alarm = source.mutableAlarm?.toImmutable() {
            saveAndReload(alarm)
        }
    }
    
}
