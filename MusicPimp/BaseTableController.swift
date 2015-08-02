//
//  BaseTableController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 14/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class BaseTableController: UITableViewController {
    
    let settings = PimpSettings.sharedInstance
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func renderTable() {
        Util.onUiThread({ () in self.tableView.reloadData() })
    }
    func info(s: String) {
        Log.info(s)
    }
    func error(e: String) {
        Log.info(e)
    }
}
