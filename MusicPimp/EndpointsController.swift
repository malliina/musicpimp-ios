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
    let endpointIdentifier = "EndpointCell"
        
    var endpoints: [Endpoint] = []
    
    var subscription: Disposable? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        endpoints = settings.endpoints()
        renderTable()
    }
    
    @IBAction func unwindToEndpoints(_ segue: UIStoryboardSegue) {
        info("Unwind")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = endpoints[(indexPath as NSIndexPath).row]
        let cell = tableView.dequeueReusableCell(withIdentifier: endpointIdentifier, for: indexPath)
        cell.textLabel?.text = item.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let index = (indexPath as NSIndexPath).row
        endpoints.remove(at: index)
        settings.saveAll(endpoints)
        tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            let destController: AnyObject = navController.viewControllers[0]
            if let editController = destController as? EditEndpointController {
                if let row = self.tableView.indexPathForSelectedRow {
                    let item = endpoints[(row as NSIndexPath).item]
                    editController.editedItem = item
                }
            } else {
                Log.error("Segue preparation error")
            }
        } else {
            Log.info("Unknown navigation controller")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.endpoints.count
    }
}

