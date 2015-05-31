//
//  EndpointSelectController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class EndpointSelectController: BaseTableController {
    
    let endpoints = PimpSettings.sharedInstance.endpoints()
    
    var selectedIndex: Int? = nil
    // override this shit. thanks for abstract classes, Apple
    var manager: EndpointManager { get { return LibraryManager.sharedInstance } }
    
    override func viewDidLoad() {
        let id = manager.loadActive().id
        if id == Endpoint.Local.id {
            selectedIndex = 0
        } else {
            if let idx = endpoints.indexOf({ $0.id == id }) {
                selectedIndex = idx + 1
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let index = indexPath.row
        let endpoint = index == 0 ? Endpoint.Local : endpoints[index-1]
        let cell = tableView.dequeueReusableCellWithIdentifier("EndpointCell", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = endpoint.name
        let accessory = index == selectedIndex ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
        cell.accessoryType = accessory
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        let index = indexPath.row
        if index == selectedIndex {
            return
        }
        let endpoint = index == 0 ? Endpoint.Local : endpoints[index-1]
        manager.saveActive(endpoint)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        
        if let previous = selectedIndex {
            let previousCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: previous, inSection: 0))
            previousCell?.accessoryType = UITableViewCellAccessoryType.None
        }
        selectedIndex = index
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return endpoints.count + 1 // +1 for local endpoint
    }

}
