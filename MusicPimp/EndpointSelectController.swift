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
    let endpointIdentifier = "EndpointCell"
    var endpoints: [Endpoint] = []
    
    var selectedIndex: Int? = nil
    // override this shit. thanks for abstract classes, Apple
    var manager: EndpointManager { get { return LibraryManager.sharedInstance } }
    var segueID: String { get { return "MusicSource" } }
    
    @IBAction func unwindToSelf(segue: UIStoryboardSegue) {
        endpoints = settings.endpoints()
        renderTable()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let navController = segue.destinationViewController as? UINavigationController {
            if let editController = navController.viewControllers[0] as? EditEndpointController,
                endpoint = sender as? Endpoint {
                    editController.editedItem = endpoint
            }
        }
    }
    
    override func viewDidLoad() {
        endpoints = settings.endpoints()
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
        let endpoint = endpointForIndex(index)
        let cell = tableView.dequeueReusableCellWithIdentifier(endpointIdentifier, forIndexPath: indexPath)
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
        let endpoint = endpointForIndex(index)
        manager.saveActive(endpoint)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        
        if let previous = selectedIndex {
            let previousCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: previous, inSection: 0))
            previousCell?.accessoryType = UITableViewCellAccessoryType.None
        }
        selectedIndex = index
    }
    
    func endpointForIndex(index: Int) -> Endpoint {
        return index == 0 ? Endpoint.Local : endpoints[index-1]
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return endpoints.count + 1 // +1 for local endpoint
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let rowIndex = indexPath.row
        if rowIndex > 0 {
            let edit = endpointRowAction(tableView, title: "Edit") {
                (index: Int) -> Void in
                let isPlayer = self.manager as? PlayerManager != nil
                let segueID = isPlayer ? "EditPlayer" : "EditSource"
                self.performSegueWithIdentifier(segueID, sender: self.endpoints[index])
            }
            let remove = endpointRowAction(tableView, title: "Remove") {
                (index: Int) -> Void in
                // TODO make EndpointsService with operations on endpoints, then listen for endpointsChanged events and react instead
                self.endpoints.removeAtIndex(index)
                self.settings.saveAll(self.endpoints)
                let visualIndex = NSIndexPath(forRow: index + 1, inSection: 0)
                tableView.deleteRowsAtIndexPaths([visualIndex], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            return [edit, remove]
        }
        // "this device" is not editable
        return []
    }
    
    func endpointRowAction(tableView: UITableView, title: String, f: Int -> Void) -> UITableViewRowAction {
        return UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title) {
            (action: UITableViewRowAction, indexPath: NSIndexPath) -> Void in
            let endIndex = indexPath.row - 1
            if endIndex >= 0 && self.endpoints.count > endIndex {
                f(endIndex)
            }
            tableView.setEditing(false, animated: true)
        }
    }
}
