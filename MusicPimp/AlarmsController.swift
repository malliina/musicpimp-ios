//
//  AlarmsController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

fileprivate extension Selector {
    static let addClicked = #selector(AlarmsController.onAddNew(_:))
}

class AlarmsController : PimpTableController, EditAlarmDelegate, AlarmEndpointDelegate {
    let log = LoggerFactory.vc("AlarmsController")
    static let endpointFooter = "MusicPimp servers support scheduled playback of music."
    static let notificationFooter = "MusicPimp sends a notification to this device when scheduled playback starts, so that you can easily silence it."
    let noAlarmsMessage = "No saved alarms"
    
    let endpointSection = 0
    let notificationSection = 1
    let alarmsSection = 2
    
    let endpointIdentifier = "EndpointCell"
    let pushEnabledIdentifier = "PushEnabledCell"
    let alarmIdentifier = "AlarmCell"
    let alarmCellKey = "MainSubCell"
    let endpointFooterIdentifier = "EndpointFooter"
    let notificationFooterIdentifier = "NotificationFooter"
    let endpointLabel = PimpLabel.footerLabel(AlarmsController.endpointFooter)
    let notificationLabel = PimpLabel.footerLabel(AlarmsController.notificationFooter)
    
    var endpoint: Endpoint? = nil
    var pushEnabled: Bool = false
    var alarms: [Alarm] = []
    var feedbackMessage: String? = nil
    
    var pushSwitch: UISwitch? = nil
    
    var isEndpointValid: Bool { return endpoint != nil }
    var footerInset: CGFloat { get { return tableView.layoutMargins.left } }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "ALARMS"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: .addClicked)
        if let tableView = self.tableView {
            tableView.register(DetailedCell.self, forCellReuseIdentifier: endpointIdentifier)
            tableView.register(PimpCell.self, forCellReuseIdentifier: pushEnabledIdentifier)
            tableView.register(SnapMainSubCell.self, forCellReuseIdentifier: alarmIdentifier)
            tableView.register(MainSubCell.self, forCellReuseIdentifier: alarmCellKey)
            tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: endpointFooterIdentifier)
            tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: notificationFooterIdentifier)
        }
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
    
    @objc func onAddNew(_ sender: UIBarButtonItem) {
        if let endpoint = endpoint {
            let dest = EditAlarmTableViewController()
            dest.delegate = self
            dest.initNewAlarm(endpoint)
            self.present(UINavigationController(rootViewController: dest), animated: true, completion: nil)
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
            log.info("Registering with previously saved push token...")
            registerWithToken(token: token, endpoint: endpoint, onSuccess: onSuccess)
        } else {
            log.info("No saved push token. Asking for permission...")
            askUserForPermission { (accessGranted) in
                if accessGranted {
                    if let token = self.settings.pushToken {
                        self.log.info("Permission granted, registering with \(endpoint.address)")
                        self.registerWithToken(token: token, endpoint: endpoint, onSuccess: onSuccess)
                    } else {
                        self.log.info("Access granted, but no token available.")
                    }
                } else {
                    self.onUiThread {
                        self.pushSwitch?.isOn = false
                    }
                    
                    let error = PimpError.simple("The user did not grant permission to send notifications")
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
        log.error(PimpError.stringify(error))
    }
    
    func unregisterNotifications(_ endpoint: Endpoint, onSuccess: @escaping () -> Void) {
        log.info("Unregistering from \(endpoint.address)...")
        let alarmLibrary = Libraries.fromEndpoint(endpoint)
        alarmLibrary.unregisterNotifications(endpoint.id, onError: onError, onSuccess: onSuccess)
    }
    
    func alarmUpdated(a: Alarm) {
        reloadAlarms()
    }
    
    func alarmDeleted() {
        reloadAlarms()
    }
    
    func endpointChanged(newEndpoint: Endpoint) {
        reloadAlarms()
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
        switch indexPath.section {
        case endpointSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: endpointIdentifier, for: indexPath)
            cell.textLabel?.text = "Playback Device"
            cell.textLabel?.textColor = PimpColors.titles
            cell.textLabel?.isEnabled = isEndpointValid
            cell.accessoryType = .disclosureIndicator
            cell.detailTextLabel?.text = endpoint?.name ?? "None"
            cell.detailTextLabel?.textColor = PimpColors.titles
            return cell
        case notificationSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: pushEnabledIdentifier, for: indexPath)
            cell.accessoryView = pushSwitch
            if let endpoint = endpoint {
                pushSwitch?.isOn = settings.notificationsEnabled(endpoint)
            }
            cell.textLabel?.text = "Notifications"
            cell.textLabel?.textColor = PimpColors.titles
            cell.textLabel?.isEnabled = isEndpointValid
            pushSwitch?.isEnabled = isEndpointValid
            return cell
        case alarmsSection:
            if alarms.count == 0 {
                return feedbackCellWithText(tableView, indexPath: indexPath, text: feedbackMessage ?? noAlarmsMessage)
            } else {
                let item = alarms[indexPath.row]
                let alarmCell: MainSubCell = loadCell(alarmCellKey, index: indexPath)
                let when = item.when
                alarmCell.main.text = item.track.title + " at " + when.time.formatted()
                alarmCell.sub.text = Day.describeDays(when.days)
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
        if indexPath.section == alarmsSection {
            return FeedbackTable.mainAndSubtitleCellHeight
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 0: return footerView(identifier: endpointFooterIdentifier, content: endpointLabel)
        case 1: return footerView(identifier: notificationFooterIdentifier, content: notificationLabel)
        default: return nil
        }
    }
    
    func footerView(identifier: String, content: UILabel) -> UITableViewHeaderFooterView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier)
        view?.contentView.addSubview(content)
        content.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(footerInset)
        }
        view?.contentView.backgroundColor = PimpColors.background
        return view
    }
    
    /// Keeps the header margins synced with the cells' margins.
    /// The cell margin seems to depend on orientation / screen size.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: self.tableView, animation: nil) { _ in
            self.endpointLabel.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(self.footerInset)
            }
            self.notificationLabel.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(self.footerInset)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0: return endpointLabel.frame.height + 10
        case 1: return notificationLabel.frame.height + 10
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        switch indexPath.section {
        case endpointSection:
            let dest = AlarmEndpointController()
            dest.delegate = self
            navigationController?.pushViewController(dest, animated: true)
            break
        case alarmsSection:
            if let alarm = alarms.get(row), let endpoint = endpoint {
                let dest = EditAlarmTableViewController()
                dest.initEditAlarm(alarm, endpoint: endpoint)
                dest.delegate = self
                navigationController?.pushViewController(dest, animated: true)
            } else {
                log.error("No alarm or endpoint")
            }
            break
        default:
            break
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return isEndpointValid
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let alarm = alarms[index]
        if let id = alarm.id {
            library.deleteAlarm(id, onError: onError) {
                self.alarms.remove(at: index)
                self.renderTable()
            }
        }
    }
        
    func onAlarmOnOffToggled(_ alarm: Alarm, uiSwitch: UISwitch) {
        let isEnabled = uiSwitch.isOn
        log.info("Toggled switch, is on: \(isEnabled) for \(alarm.track.title)")
        let mutable = MutableAlarm(a: alarm)
        mutable.enabled = isEnabled
        if let updated = mutable.toImmutable() {
            saveAndReload(updated)
        }
    }
    
}
