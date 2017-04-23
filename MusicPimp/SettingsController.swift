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
    @IBOutlet var creditsCell: PimpCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let libraryManager = LibraryManager.sharedInstance
        let playerManager = PlayerManager.sharedInstance
        let _ = libraryManager.changed.addHandler(self) { (sc) -> (Endpoint) -> () in
            sc.onLibraryChanged
        }
        let _ = playerManager.changed.addHandler(self) { (sc) -> (Endpoint) -> () in
            sc.onPlayerChanged
        }
        let _ = settings.cacheEnabledChanged.addHandler(self) { (sc) -> (Bool) -> () in
            sc.onCacheEnabledChanged
        }
        navigationItem.title = "SETTINGS"
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: PimpColors.titleFont
        ]
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
        let section = indexPath.section
        let row = indexPath.row
        if section == 3 && row == 1 {
            // Credits
//            let dest = Credits()
            let dest = Credits(nibName: "Credits", bundle: .main)
            self.navigationController?.pushViewController(dest, animated: false)
        }
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
    }
}
