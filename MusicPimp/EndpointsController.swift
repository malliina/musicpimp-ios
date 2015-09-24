//
//  EndpointsController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class EndpointsController: BaseTableController {
        
    var endpoints: [Endpoint] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        endpoints = settings.endpoints()
        renderTable()
    }
    
    @IBAction func unwindToEndpoints(segue: UIStoryboardSegue) {
        info("Unwind")
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = endpoints[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("EndpointCell", forIndexPath: indexPath) 
        cell.textLabel?.text = item.name
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let index = indexPath.row
        endpoints.removeAtIndex(index)
        settings.saveAll(endpoints)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let navController = segue.destinationViewController as? UINavigationController {
            let destController: AnyObject = navController.viewControllers[0]
            if let editController = destController as? EditEndpointController {
                if let row = self.tableView.indexPathForSelectedRow {
                    let item = endpoints[row.item]
                    editController.editedItem = item
                }
            } else {
                Log.error("hmm")
            }
        } else {
            Log.info("Unknown navigation controller")
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.endpoints.count
    }
}

