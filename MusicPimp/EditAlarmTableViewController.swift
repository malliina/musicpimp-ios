//
//  EditAlarmTableViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 30/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class EditAlarmTableViewController: BaseTableController {
//    let timePickerCellIdentifier = "TimePickerCell"
//    let normalRowHeight = 44
//    let timePickerRowHeight = 176
    
    @IBOutlet var datePicker: UIDatePicker!
    
    @IBAction func save(sender: UIBarButtonItem) {
        
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
//        if let reuseIdentifier = cell.reuseIdentifier {
//            switch reuseIdentifier {
//            case timePickerCellIdentifier:
//                break
//            case _:
//                break
//            }
//        }
        return cell
    }
}
