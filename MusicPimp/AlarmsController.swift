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
    let log = LoggerFactory.shared.vc(AlarmsController.self)
    static let endpointFooter = "MusicPimp servers support scheduled playback of music."
    static let notificationFooter = "Receive a notification when scheduled playback starts, so that you can easily silence it."
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
    let schedulesFooterIdentifier = "SchedulesFooter"
    let endpointLabel = PimpLabel.footerLabel(AlarmsController.endpointFooter)
    let notificationLabel = PimpLabel.footerLabel(AlarmsController.notificationFooter)
    let schedulesLabel = PimpLabel.footerLabel("Scheduled tracks")
    
    var endpoint: Endpoint? = nil
    var pushEnabled: Bool = false
    var alarms: [Alarm] = []
    var feedbackMessage: String? = nil
    
    var pushSwitch: UISwitch? = nil
    
    var isEndpointValid: Bool { endpoint != nil }
    var footerInset: CGFloat { get { tableView.layoutMargins.left } }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "ALARMS"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: .addClicked)
        if let tableView = self.tableView {
            tableView.register(DisclosureCell.self, forCellReuseIdentifier: endpointIdentifier)
            tableView.register(DetailedCell.self, forCellReuseIdentifier: pushEnabledIdentifier)
            tableView.register(SnapMainSubCell.self, forCellReuseIdentifier: alarmIdentifier)
            tableView.register(MainSubCell.self, forCellReuseIdentifier: alarmCellKey)
            tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: endpointFooterIdentifier)
            tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: notificationFooterIdentifier)
            tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: schedulesFooterIdentifier)
        }
        reloadAlarms()
        let onOff = PimpSwitch { (uiSwitch) in
            self.didToggleNotifications(uiSwitch)
        }
        pushSwitch = onOff
        run(settings.defaultAlarmEndpointChanged, onResult: self.didChangeDefaultAlarmEndpoint)
    }
    
    /// Keeps the header margins synced with the cells' margins.
    /// The cell margin seems to depend on orientation / screen size.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: self.tableView, animation: nil) { _ in
            self.snapHeader(header: self.endpointLabel)
            self.snapHeader(header: self.notificationLabel)
            self.snapHeader(header: self.schedulesLabel)
            // recalculates header heights, because margins might change on transition
            self.tableView.reloadData()
        }
    }
    
    func snapHeader(header: UIView) {
        header.snp.remakeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(self.footerInset)
        }
    }
    
    @objc func onAddNew(_ sender: UIBarButtonItem) {
        if let endpoint = endpoint {
            let dest = EditAlarmTableViewController(endpoint: endpoint, delegate: self)
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
            toggleRegistration(endpoint)
        }
    }
    
    func registerNotifications(_ endpoint: Endpoint) {
        if let token = settings.pushToken {
            log.info("Registering with previously saved push token...")
            registerWithToken(token: token, endpoint: endpoint)
        } else {
            log.info("No saved push token. Asking for permission...")
            askUserForPermission { (accessGranted) in
                if accessGranted {
                    if let token = self.settings.pushToken {
                        self.log.info("Permission granted, registering with \(endpoint.address)")
                        self.registerWithToken(token: token, endpoint: endpoint)
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
    
    func registerWithToken(token: PushToken, endpoint: Endpoint) {
        let alarmLibrary = Libraries.fromEndpoint(endpoint)
        alarmLibrary.registerNotifications(token, tag: endpoint.id).subscribe { (event) in
            switch event {
            case .success(_): let _ = self.settings.saveNotificationsEnabled(endpoint, enabled: true)
            case .failure(let err): self.onRegisterError(error: err, endpoint: endpoint)
            }
        }.disposed(by: bag)
    }
    
    func askUserForPermission(onResult: @escaping (Bool) -> Void) {
        run(PimpSettings.sharedInstance.notificationPermissionChanged.take(1), onResult: onResult)
        PimpNotifications.sharedInstance.initNotifications(UIApplication.shared)
    }
    
    func onRegisterError(error: Error, endpoint: Endpoint) {
        log.error(error.message)
    }
    
    func unregisterNotifications(_ endpoint: Endpoint) {
        log.info("Unregistering from \(endpoint.address)...")
        let alarmLibrary = Libraries.fromEndpoint(endpoint)
        runSingle(alarmLibrary.unregisterNotifications(endpoint.id)) { _ in
            let _ = self.settings.saveNotificationsEnabled(endpoint, enabled: false)
        }
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
        runSingle(library.alarms()) { alarms in
            self.onAlarms(alarms)
        }
    }
    
    func saveAndReload(_ alarm: Alarm) {
        if let endpoint = endpoint {
            let library = Libraries.fromEndpoint(endpoint)
            runSingle(library.saveAlarm(alarm)) { _ in
                self.loadAlarms(library)
            }
        }
    }
    
    func onAlarms(_ alarms: [Alarm]) {
        feedbackMessage = nil
        onUiThread {
            self.alarms = alarms
            self.reloadTable(feedback: nil)
        }
    }
    
    func onAlarmError(_ error: PimpError) {
        feedbackMessage = error.message
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
            let cell: DisclosureCell = loadCell(endpointIdentifier, index: indexPath)
//            let cell = tableView.dequeueReusableCell(withIdentifier: endpointIdentifier, for: indexPath)
            cell.title.text = "Playback Device"
            cell.title.isEnabled = isEndpointValid
//            cell.accessoryType = .disclosureIndicator
            cell.detail.text = endpoint?.name ?? "None"
            return cell
        case notificationSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: pushEnabledIdentifier, for: indexPath)
            cell.accessoryView = pushSwitch
            if let endpoint = endpoint {
                pushSwitch?.isOn = settings.notificationsEnabled(endpoint)
            }
            cell.textLabel?.text = "Notifications"
            cell.textLabel?.isEnabled = isEndpointValid
            pushSwitch?.isEnabled = isEndpointValid
            return cell
        case alarmsSection:
            if alarms.count == 0 {
                return feedbackCellWithText(tableView, indexPath: indexPath, text: feedbackMessage ?? noAlarmsMessage)
            } else {
                let item = alarms[indexPath.row]
                let alarmCell: MainSubCell = loadCell(alarmCellKey, index: indexPath)
                alarmCell.zeroAccessoryMargin = false
                let when = item.when
                alarmCell.main.text = item.track.title + " at " + when.time.formatted()
                alarmCell.sub.text = Day.describeDays(Set(when.days))
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        /// This method is called before viewForHeaderInSection. So we need to check how much space the label will take,
        /// then return a height that takes the margin into account as well.
        switch section {
        case 0: return endpointLabel.tableHeaderHeight(tableView) + 8
        case 1: return notificationLabel.tableHeaderHeight(tableView) + 8
        case 2: return schedulesLabel.tableHeaderHeight(tableView) + 8
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0: return footerView(identifier: endpointFooterIdentifier, content: endpointLabel)
        case 1: return footerView(identifier: notificationFooterIdentifier, content: notificationLabel)
        case 2: return footerView(identifier: schedulesFooterIdentifier, content: schedulesLabel)
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return ""
    }
    
    /// Overridden, otherwise the footer is not shown
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return super.tableView(tableView, viewForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.contentView.backgroundColor = PimpColors.shared.background
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 22
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        switch indexPath.section {
        case endpointSection:
            let dest = AlarmEndpointController(d: self)
            navigationController?.pushViewController(dest, animated: true)
            break
        case alarmsSection:
            if let alarm = alarms.get(row), let endpoint = endpoint {
                let dest = EditAlarmTableViewController(editable: alarm, endpoint: endpoint, delegate: self)
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let alarm = alarms[index]
        if let id = alarm.id {
            runSingle(library.deleteAlarm(id)) { _ in
                self.alarms.remove(at: index)
                self.renderTable()
            }
        }
    }
        
    func onAlarmOnOffToggled(_ alarm: Alarm, uiSwitch: UISwitch) {
        let isEnabled = uiSwitch.isOn
        log.info("Toggled switch, is on: \(isEnabled) for \(alarm.track.title)")
        let mutable = MutableAlarm(alarm)
        mutable.enabled = isEnabled
        if let updated = mutable.toImmutable() {
            saveAndReload(updated)
        }
    }
    
}
