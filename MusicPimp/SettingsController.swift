//
//  SettingsController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class SettingsController: CacheInfoController {
    let libraryManager = LibraryManager.sharedInstance
    let playerManager = PlayerManager.sharedInstance
    
    var activeLibrary: Endpoint { return libraryManager.loadActive() }
    var activePlayer: Endpoint  { return playerManager.loadActive() }
    
    @IBOutlet var libraryDetail: UILabel!
    @IBOutlet var playerDetail: UILabel!
    @IBOutlet var sourcePicker: UIPickerView!
    
    @IBOutlet var cacheDetail: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let libraryManager = LibraryManager.sharedInstance
        let playerManager = PlayerManager.sharedInstance
        libraryManager.changed.addHandler(self) { (sc) -> (Endpoint) -> () in
            sc.onLibraryChanged
        }
        playerManager.changed.addHandler(self) { (sc) -> (Endpoint) -> () in
            sc.onPlayerChanged
        }
        settings.cacheEnabledChanged.addHandler(self) { (sc) -> (Bool) -> () in
            sc.onCacheEnabledChanged
        }
    }
    
    fileprivate func onLibraryChanged(_ newLibrary: Endpoint) {
        renderTable()
    }
    
    fileprivate func onPlayerChanged(_ newPlayer: Endpoint) {
        renderTable()
    }
    
    fileprivate func onCacheEnabledChanged(_ newEnabled: Bool) {
        renderTable()
    }
    
    override func onCacheLimitChanged(_ newLimit: StorageSize) {
        renderTable()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let reuseIdentifier = cell.reuseIdentifier {
            cell.detailTextLabel?.text = textForIdentifier(reuseIdentifier)
        }
        return cell
    }
    
    fileprivate func textForIdentifier(_ reuseIdentifier: String) -> String {
        switch reuseIdentifier {
            case "MusicSource": return activeLibrary.name
            case "PlaybackDevice": return activePlayer.name
            case "Cache": return settings.cacheEnabled ? currentLimitDescription : "off"
            default: return ""
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
    }
}
