//
//  EditAlarmTableViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 30/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

fileprivate extension Selector {
    static let saveClicked = #selector(EditAlarmTableViewController.onSave(_:))
    static let cancelClicked = #selector(EditAlarmTableViewController.onCancel(_:))
}

protocol EditAlarmDelegate {
    func alarmUpdated(a: Alarm)
    func alarmDeleted()
}

class EditAlarmTableViewController: BaseTableController {
    let log = LoggerFactory.shared.vc(EditAlarmTableViewController.self)
    let timePickerIdentifier = "TimePickerCell"
    let repeatIdentifier = "RepeatCell"
    let trackIdentifier = "TrackCell"
    let playIdentifier = "PlayCell"
    let deleteAlarmIdentifier = "DeleteCell"
    
    var libraryManager: LibraryManager { LibraryManager.sharedInstance }
    var playerManager: PlayerManager { PlayerManager.sharedInstance }
    
    private var mutableAlarm: MutableAlarm? = nil
    private var endpoint: Endpoint? = nil
    private var player: PlayerType? = nil
    private var delegate: EditAlarmDelegate? = nil
    private var isPlaying: Bool = false
    
    var playbackBag = DisposeBag()
    
    let datePicker = UIDatePicker()
    
    init(editable: Alarm, endpoint: Endpoint, delegate: EditAlarmDelegate) {
        super.init()
        self.mutableAlarm = MutableAlarm(editable)
        self.endpoint = endpoint
        self.delegate = delegate
    }
    
    init(endpoint: Endpoint, delegate: EditAlarmDelegate) {
        super.init()
        self.endpoint = endpoint
        self.delegate = delegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "EDIT ALARM"
        if self.mutableAlarm == nil {
            self.mutableAlarm = MutableAlarm()
        }
        [repeatIdentifier, trackIdentifier].forEach { (id) in
            self.tableView!.register(DetailedCell.self, forCellReuseIdentifier: id)
        }
        [playIdentifier, deleteAlarmIdentifier, timePickerIdentifier].forEach { (id) in
            registerCell(reuseIdentifier: id)
        }
        initUI()
    }
    
    
    func initUI() {
        datePicker.datePickerMode = .time
        datePicker.minuteInterval = 5
        // hack
        datePicker.setValue(colors.titles, forKey: "textColor")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: .cancelClicked)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: .saveClicked)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTable(feedback: nil)
        if let endpoint = endpoint {
            let p = Players.sharedInstance.fromEndpoint(endpoint)
            p.open().subscribe { (event) in
                switch event {
                case .next(_): ()
                case .error(let err): self.onConnectError(err)
                case .completed:
                    p.stateEvent.subscribe(onNext: { (newState) in
                        self.onPlayerState(newState)
                    }).disposed(by: self.playbackBag)
                    self.onPlayerState(p.current().state)
                }
            }.disposed(by: playbackBag)
            player = p
        }
    }
    
    func onPlayerState(_ state: PlaybackState) {
        onUiThread {
            self.isPlaying = state == .Playing
            let playbackButtonRow = IndexPath(row: 0, section: 2)
            self.tableView.reloadRows(at: [playbackButtonRow], with: .automatic)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        updateDate()
        player?.close()
        playbackBag = DisposeBag()
        super.viewWillDisappear(animated)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 2
        case 2: return 1
        case 3: return 1
        default: return 0
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        4
    }

    func initEditAlarm(_ alarm: Alarm, endpoint: Endpoint) {
        self.mutableAlarm = MutableAlarm(alarm)
        self.endpoint = endpoint
    }
    
    func initNewAlarm(_ endpoint: Endpoint) {
        self.endpoint = endpoint
    }
  
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
        } else {
            log.error("Unable to save alarm - no alarm available")
        }
    }
    
    // adapted from http://stackoverflow.com/a/12741639
    func changeDate(_ datePicker: UIDatePicker, time: ClockTime) {
        let components = time.dateComponents(datePicker.date)
        if let date = (components as NSDateComponents).date {
            datePicker.date = date
        }
    }
    
    @objc func onSave(_ sender: UIBarButtonItem) {
        updateDate()
        if let endpoint = endpoint, let alarm = mutableAlarm?.toImmutable() {
            let library = Libraries.fromEndpoint(endpoint)
            runSingle(library.saveAlarm(alarm)) { _ in
                self.delegate?.alarmUpdated(a: alarm)
            }
        }
        goBack()
    }
    
    @objc func onCancel(_ sender: UIBarButtonItem) {
        goBack()
    }
    
    func identifierFor(_ indexPath: IndexPath) -> String? {
        switch indexPath.section {
        case 0: return timePickerIdentifier
        case 1: return indexPath.row == 0 ? trackIdentifier : repeatIdentifier
        case 2: return playIdentifier
        case 3: return deleteAlarmIdentifier
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = identifierFor(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: id ?? "")!
        if let reuseIdentifier = cell.reuseIdentifier {
            switch reuseIdentifier {
            case timePickerIdentifier:
                if let time = mutableAlarm?.when {
                    changeDate(datePicker, time: ClockTime(hour: time.hour, minute: time.minute))
                }
                cell.contentView.addSubview(datePicker)
                datePicker.snp.makeConstraints { (make) in
                    make.leadingMargin.trailingMargin.equalToSuperview().inset(16)
                    make.height.lessThanOrEqualToSuperview()
                }
                break
            case repeatIdentifier:
                if let label = cell.textLabel {
                    label.text = "Repeat"
                }
//                let emptyDays = Set<Day>()
                let activeDays = mutableAlarm?.when.days ?? []
                cell.detailTextLabel?.text = Day.describeDays(Set(activeDays))
                break
            case trackIdentifier:
                if let label = cell.textLabel {
                    label.text = "Track"
                }
                cell.detailTextLabel?.text = mutableAlarm?.track?.title ?? "No track"
                break
            case playIdentifier:
                if let label = cell.textLabel {
                    label.text = isPlaying ? "Stop Playback" : "Play Now"
                    label.isEnabled = mutableAlarm?.track != nil
                    label.textAlignment = .center
                    label.textColor = colors.titles
                }
                break
            case deleteAlarmIdentifier:
                if let label = cell.textLabel {
                    label.text = "Delete Alarm"
                    label.isEnabled = mutableAlarm?.id != nil
                    label.textColor = colors.deletion
                    label.textAlignment = .center
                }
                cell.selectionStyle = .default
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
            case trackIdentifier:
                let dest = SearchAlarmTrackController()
                dest.alarm = self.mutableAlarm
                navigationController?.pushViewController(dest, animated: true)
                break
            case repeatIdentifier:
                let dest = RepeatDaysController()
                dest.alarm = self.mutableAlarm
                navigationController?.pushViewController(dest, animated: true)
                break
            case deleteAlarmIdentifier:
                if let alarmId = mutableAlarm?.id, let endpoint = endpoint {
                    tableView.deselectRow(at: indexPath, animated: false)
                    runSingle(Libraries.fromEndpoint(endpoint).deleteAlarm(alarmId)) { _ in
                        self.delegate?.alarmDeleted()
                        Util.onUiThread {
                            self.goBack()
                        }
                    }
                }
                break
            case playIdentifier:
                tableView.deselectRow(at: indexPath, animated: false)
                if let track = mutableAlarm?.track, let _ = endpoint, let player = player {
                    if isPlaying {
                        let _ = player.pause()
                    } else {
                        let _ = player.resetAndPlay(tracks: [track])
                    }
                    // self.log.debug("Playing \(track.title): \(success)")
                } else {
                    let desc = mutableAlarm?.track?.title ?? "no alarm or track"
                    log.error("Cannot play track, \(desc)")
                }
                break
            default:
                break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let v = view as? UITableViewHeaderFooterView {
            v.tintColor = colors.background
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section > 0 ? 44 : 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let isDatePicker = indexPath.section == 0 && indexPath.row == 0
        return isDatePicker ? 176 : super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    func onConnectError(_ e: Error) {
        
    }
}

extension UIViewController {
    @objc func goBack() {
        let isAddMode = presentingViewController != nil
        if isAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}
