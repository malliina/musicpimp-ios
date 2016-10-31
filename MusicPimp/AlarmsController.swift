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
        let _ = settings.defaultAlarmEndpointChanged.addHandler(self) { (ac) -> (Endpoint) -> () in
            ac.didChangeDefaultAlarmEndpoint
        }
    }
    
    func didChangeDefaultAlarmEndpoint(_ e: Endpoint) {
        reloadAlarms()
    }
    
    func didToggleNotifications(_ uiSwitch: UISwitch) {
        let isOn = uiSwitch.isOn
        if let endpoint = endpoint {
            let toggleRegistration = isOn ? registerNotifications : unregisterNotifications
            toggleRegistration(endpoint) {
                let _ = self.settings.saveNotificationsEnabled(endpoint, enabled: isOn)
            }
        }
    }
    
    func registerNotifications(_ endpoint: Endpoint, onSuccess: @escaping () -> Void) {
        if let token = settings.pushToken {
            registerWithToken(token: token, endpoint: endpoint, onSuccess: onSuccess)
        } else {
            askUserForPermission { (accessGranted) in
                if let token = self.settings.pushToken, accessGranted {
                    self.registerWithToken(token: token, endpoint: endpoint, onSuccess: onSuccess)
                } else {
                    let error = PimpError.simple("User did not grant permission to send notifications")
                    self.onRegisterError(error: error, endpoint: endpoint)
                }
            }
        }
    }
    
    func registerWithToken(token: PushToken, endpoint: Endpoint, onSuccess: @escaping () -> Void) {
        let alarmLibrary = Libraries.fromEndpoint(endpoint)
        alarmLibrary.registerNotifications(token, tag: endpoint.id, onError: { (err) in self.onRegisterError(error: err, endpoint: endpoint) }, onSuccess: onSuccess)
    }
    
    func askUserForPermission(onResult: @escaping (Bool) -> Void) {
        let _ = PimpSettings.sharedInstance.notificationPermissionChanged.first(self) { (view) -> (Bool) -> () in
            onResult
        }
        PimpNotifications.sharedInstance.initNotifications(UIApplication.shared)
    }
    
    func onRegisterError(error: PimpError, endpoint: Endpoint) {
        Log.error(PimpError.stringify(error))
    }
    
    func unregisterNotifications(_ endpoint: Endpoint, onSuccess: @escaping () -> Void) {
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
    
    func loadAlarms(_ endpoint: Endpoint) {
        loadAlarms(Libraries.fromEndpoint(endpoint))
    }
    
    func loadAlarms(_ library: LibraryType) {
        library.alarms(onAlarmError, f: onAlarms)
    }
    
    func saveAndReload(_ alarm: Alarm) {
        if let endpoint = endpoint {
            let library = Libraries.fromEndpoint(endpoint)
            library.saveAlarm(alarm, onError: onError) {
                self.loadAlarms(library)
            }
        }
    }
    
    func onAlarms(_ alarms: [Alarm]) {
        feedbackMessage = nil
        self.alarms = alarms
        renderTable()
    }
    
    func onAlarmError(_ error: PimpError) {
        let message = PimpError.stringify(error)
        feedbackMessage = message
        renderTable()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Max one because we display feedback to the user if the table is empty
        if section == alarmsSection {
            return max(alarms.count, 1)
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath as NSIndexPath).section {
        case endpointSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: endpointIdentifier, for: indexPath)
            cell.detailTextLabel?.text = endpoint?.name ?? "None"
            cell.textLabel?.isEnabled = isEndpointValid
            return cell
        case notificationSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: pushEnabledIdentifier, for: indexPath)
            cell.accessoryView = pushSwitch
            if let endpoint = endpoint {
                pushSwitch?.isOn = settings.notificationsEnabled(endpoint)
            }
            cell.textLabel?.isEnabled = isEndpointValid
            pushSwitch?.isEnabled = isEndpointValid
            return cell
        case alarmsSection:
            if alarms.count == 0 {
                return feedbackCellWithText(tableView, indexPath: indexPath, text: feedbackMessage ?? noAlarmsMessage)
            } else {
                let item = alarms[(indexPath as NSIndexPath).row]
                let alarmCell: MainSubCell = loadCell(alarmCellKey, index: indexPath)
                let when = item.when
                alarmCell.mainTitle.text = item.track.title + " at " + when.time.formatted()
                alarmCell.subtitle.text = Day.describeDays(when.days)
                let uiSwitch = PimpSwitch { (uiSwitch) in
                    self.onAlarmOnOffToggled(item, uiSwitch: uiSwitch)
                }
                uiSwitch.isOn = item.enabled
                alarmCell.accessoryView = uiSwitch
                return alarmCell
            }
        default:
            // We never get here
            return tableView.dequeueReusableCell(withIdentifier: BaseMusicController.feedbackIdentifier, for: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).section == alarmsSection {
            return FeedbackTable.mainAndSubtitleCellHeight
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case endpointSection:
            return "MusicPimp servers support scheduled playback of music."
        case notificationSection:
            return "MusicPimp sends a notification to this device when scheduled playback starts, so that you can easily silence it."
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = (indexPath as NSIndexPath).row
        if (indexPath as NSIndexPath).section == alarmsSection {
            if let alarm = alarms.get(row),
                let endpoint = endpoint,
                let storyboard = storyboard,
                let dest = storyboard.instantiateViewController(withIdentifier: "EditAlarm") as? EditAlarmTableViewController {
                dest.initEditAlarm(alarm, endpoint: endpoint)
                self.navigationController?.pushViewController(dest, animated: true)
            } else {
                Log.error("No alarm, endpoint, storyboard or destination")
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return isEndpointValid
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let index = (indexPath as NSIndexPath).row
        let alarm = alarms[index]
        if let id = alarm.id {
            library.deleteAlarm(id, onError: onError) {
                self.alarms.remove(at: index)
                self.renderTable()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueDestination = segue.destination
        if let endpoint = endpoint {
            if let dest = segueDestination as? EditAlarmTableViewController {
                if let row = self.tableView.indexPathForSelectedRow {
                    let index = (row as NSIndexPath).item
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
                    Log.error("Unexpected destination \(segue.destination)")
                }
            }
        } else {
            Log.error("Cannot configure alarms without a valid playback device")
        }
    }
    
    @IBAction func unwindToAlarms(_ sender: UIStoryboardSegue) {
        if let source = sender.source as? EditAlarmTableViewController,
            let alarm = source.mutableAlarm?.toImmutable() {
            saveAndReload(alarm)
        }
    }
    
    func onAlarmOnOffToggled(_ alarm: Alarm, uiSwitch: UISwitch) {
        let isEnabled = uiSwitch.isOn
        info("Toggled switch, is on: \(isEnabled) for \(alarm.track.title)")
        let mutable = MutableAlarm(a: alarm)
        mutable.enabled = isEnabled
        if let updated = mutable.toImmutable() {
            saveAndReload(updated)
        }
    }
    
}
