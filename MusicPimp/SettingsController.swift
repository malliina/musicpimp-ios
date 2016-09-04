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
        libraryManager.changed.addHandler(self) { (sc) -> Endpoint -> () in
            sc.onLibraryChanged
        }
        playerManager.changed.addHandler(self) { (sc) -> Endpoint -> () in
            sc.onPlayerChanged
        }
        settings.cacheEnabledChanged.addHandler(self) { (sc) -> Bool -> () in
            sc.onCacheEnabledChanged
        }
    }
    
    private func onLibraryChanged(newLibrary: Endpoint) {
        renderTable()
    }
    
    private func onPlayerChanged(newPlayer: Endpoint) {
        renderTable()
    }
    
    private func onCacheEnabledChanged(newEnabled: Bool) {
        renderTable()
    }
    
    override func onCacheLimitChanged(newLimit: StorageSize) {
        renderTable()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let reuseIdentifier = cell.reuseIdentifier {
            cell.detailTextLabel?.text = textForIdentifier(reuseIdentifier)
        }
        return cell
    }
    
    private func textForIdentifier(reuseIdentifier: String) -> String {
        switch reuseIdentifier {
            case "MusicSource": return activeLibrary.name
            case "PlaybackDevice": return activePlayer.name
            case "Cache": return settings.cacheEnabled ? currentLimitDescription : "off"
            default: return ""
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
}
