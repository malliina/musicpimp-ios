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
    //var listener: Disposable? = nil
    
    @IBOutlet var libraryDetail: UILabel!
    @IBOutlet var playerDetail: UILabel!
    @IBOutlet var sourcePicker: UIPickerView!
    
    @IBOutlet var cacheDetail: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let libraryManager = LibraryManager.sharedInstance
        let playerManager = PlayerManager.sharedInstance
        libraryManager.changed.addHandler(self, handler: { (sc) -> Endpoint -> () in
            sc.onLibraryChanged
        })
        playerManager.changed.addHandler(self, handler: { (sc) -> Endpoint -> () in
            sc.onPlayerChanged
        })
        settings.cacheEnabledChanged.addHandler(self, handler: { (sc) -> Bool -> () in
            sc.onCacheEnabledChanged
        })
//        settings.cacheLimitChanged.addHandler(self, handler: { (sc) -> StorageSize -> () in
//            sc.onCacheLimitChanged
//        })
    }
    
    override func viewWillAppear(animated: Bool) {
        
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
            var text: String? = nil
            switch reuseIdentifier {
                case "MusicSource":
                    text = activeLibrary.name
                break
                case "PlaybackDevice":
                    text = activePlayer.name
                break
                case "Cache":
                    text = settings.cacheEnabled ? currentLimitDescription : "off"
                break
                case "Alarm":
                    text = "off"
                break
                default:
                break
            }
            if let text = text {
                cell.detailTextLabel?.text = text
            }
        }
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
}
