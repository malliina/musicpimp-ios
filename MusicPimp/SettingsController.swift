//
//  SettingsController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class RowSpec {
    static let empty = RowSpec(reuseIdentifier: "", text: "")
    let reuseIdentifier: String
    let text: String
    
    init(reuseIdentifier: String, text: String) {
        self.reuseIdentifier = reuseIdentifier
        self.text = text
    }
}

class SettingsController: CacheInfoController, EditEndpointDelegate, PlayerEndpointDelegate, LibraryEndpointDelegate {
    private let log = LoggerFactory.shared.vc(SettingsController.self)
    let detailId = "DetailedCell"
    let sectionHeaderHeight: CGFloat = 44
    let playbackDeviceId = "PlaybackDevice"
    let musicSourceId = "MusicSource"
    let cacheId = "Cache"
    let alarmId = "Alarm"
    let aboutId = "About"
    let creditsId = "Credits"
    
    let libraryManager = LibraryManager.sharedInstance
    let playerManager = PlayerManager.sharedInstance
    
    var activeLibrary: Endpoint { libraryManager.loadActive() }
    var activePlayer: Endpoint  { playerManager.loadActive() }
    
    let sourcePicker = UIPickerView()
    let listener = EndpointsListener()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        [playbackDeviceId, musicSourceId, cacheId, alarmId, aboutId, creditsId].forEach { id in
            self.tableView?.register(DisclosureCell.self, forCellReuseIdentifier: id)
        }
        run(settings.cacheEnabledChanged, onResult: self.onCacheEnabledChanged)
        listener.players = self
        listener.libraries = self
        listener.subscribe()
        navigationItem.title = "SETTINGS"
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: colors.titleFont
        ]
    }
    
    func endpointAddedOrUpdated(_ endpoint: Endpoint) {
        renderTable()
    }
    
    func onLibraryUpdated(to newLibrary: Endpoint) {
        renderTable()
    }
    
    func onPlayerUpdated(to newPlayer: Endpoint) {
        renderTable()
    }
    
    fileprivate func onCacheEnabledChanged(_ newEnabled: Bool) {
        renderTable()
    }
    
    override func onCacheLimitChanged(_ newLimit: StorageSize) {
        renderTable()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let spec = specForRow(indexPath: indexPath) ?? RowSpec(reuseIdentifier: "", text: "")
        let cell: DisclosureCell = loadCell(spec.reuseIdentifier, index: indexPath)
        cell.title.text = spec.text
//        cell.textLabel?.textColor = colors.titles
//        cell.accessoryType = .disclosureIndicator
        cell.detail.text = textForIdentifier(spec.reuseIdentifier)
//        cell.detailTextLabel?.textColor = colors.titles
        return cell
    }
    
    func specForRow(indexPath: IndexPath) -> RowSpec? {
        switch indexPath.section {
        case 0:
        switch indexPath.row {
        case 0: return RowSpec(reuseIdentifier: musicSourceId, text: "Music source")
        case 1: return RowSpec(reuseIdentifier: playbackDeviceId, text: "Play music on")
        default: return nil
        }
        case 1: return RowSpec(reuseIdentifier: cacheId, text: "Cache")
        case 2: return RowSpec(reuseIdentifier: alarmId, text: "Alarms")
        case 3:
        switch indexPath.row {
        case 0: return RowSpec(reuseIdentifier: aboutId, text: "MusicPimp Premium")
        case 1: return RowSpec(reuseIdentifier: creditsId, text: "Credits")
        default: return nil
        }
        default: return nil
        }
    }

    fileprivate func textForIdentifier(_ reuseIdentifier: String) -> String {
        switch reuseIdentifier {
            case musicSourceId: return activeLibrary.name
            case playbackDeviceId: return activePlayer.name
            case cacheId: return settings.cacheEnabled ? currentLimitDescription : "off"
            default: return ""
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 1
        case 2: return 1
        case 3: return 2
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "PLAYBACK"
        case 1: return "STORAGE"
        case 2: return "ALARM CLOCK"
        case 3: return "ABOUT"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sectionHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let v = view as? UITableViewHeaderFooterView {
            v.tintColor = colors.background
            v.textLabel?.font = v.textLabel?.font.withSize(12)
            v.textLabel?.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let dest = destinationFor(indexPath: indexPath) {
            self.navigationController?.pushViewController(dest, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func destinationFor(indexPath: IndexPath) -> UIViewController? {
        if let id = tableView.cellForRow(at: indexPath)?.reuseIdentifier {
            switch id {
            case musicSourceId:
                let dest = SourceSettingController()
                dest.delegate = self
                return dest
            case playbackDeviceId:
                let dest = PlayerSettingController()
                dest.delegate = self
                return dest
            case cacheId:
                return CacheTableController()
            case alarmId:
                return AlarmsController()
            case aboutId:
                return IAPViewController()
            case creditsId:
                return Credits()
            default:
                return nil
            }
        }
        return nil
    }
}
