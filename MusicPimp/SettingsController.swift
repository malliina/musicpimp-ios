//
//  SettingsController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class SettingsController: BaseTableController {
    
    let settings = PimpSettings.sharedInstance
    var endpoints: [Endpoint] = []
    var activeLibrary: Endpoint? = nil
    var activePlayer: Endpoint? = nil
    //var listener: Disposable? = nil
    
    @IBOutlet var sourcePicker: UIPickerView!
    
    override func viewWillAppear(animated: Bool) {
        endpoints = settings.endpoints()
        activeLibrary = LibraryManager.sharedInstance.loadActive()
        activePlayer = PlayerManager.sharedInstance.loadActive()
        renderTable()
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let c = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        switch indexPath.row {
        case 0:
            c.detailTextLabel?.text = activeLibrary?.name ?? "none"
            break
        case 1:
            c.detailTextLabel?.text = activePlayer?.name ?? "none"
            break
        default:
            break
        }
        return c
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
}
