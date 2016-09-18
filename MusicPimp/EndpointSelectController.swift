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
    
    @IBAction func unwindToSelf(_ segue: UIStoryboardSegue) {
        endpoints = settings.endpoints()
        renderTable()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let editController = navController.viewControllers[0] as? EditEndpointController,
                let endpoint = sender as? Endpoint {
                    editController.editedItem = endpoint
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        endpoints = settings.endpoints()
        updateSelected(manager.loadActive())
    }
    
    func updateSelected(_ selected: Endpoint) {
        let id = selected.id
        if id == Endpoint.Local.id {
            selectedIndex = 0
        } else {
            if let idx = endpoints.index(where: { $0.id == id }) {
                selectedIndex = idx + 1
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        renderTable()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = (indexPath as NSIndexPath).row
        let endpoint = endpointForIndex(index)
        let cell = tableView.dequeueReusableCell(withIdentifier: endpointIdentifier, for: indexPath)
        cell.textLabel?.text = endpoint.name
        let accessory = index == selectedIndex ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        cell.accessoryType = accessory
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let index = (indexPath as NSIndexPath).row
        if index == selectedIndex {
            return
        }
        let endpoint = endpointForIndex(index)
        manager.saveActive(endpoint)
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = UITableViewCellAccessoryType.checkmark
        
        if let previous = selectedIndex {
            let previousCell = tableView.cellForRow(at: IndexPath(row: previous, section: 0))
            previousCell?.accessoryType = UITableViewCellAccessoryType.none
        }
        selectedIndex = index
    }
    
    func endpointForIndex(_ index: Int) -> Endpoint {
        return index == 0 ? Endpoint.Local : endpoints[index-1]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return endpoints.count + 1 // +1 for local endpoint
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let rowIndex = (indexPath as NSIndexPath).row
        if rowIndex > 0 {
            let edit = endpointRowAction(tableView, title: "Edit") {
                (index: Int) -> Void in
                let isPlayer = self.manager as? PlayerManager != nil
                let segueID = isPlayer ? "EditPlayer" : "EditSource"
                self.performSegue(withIdentifier: segueID, sender: self.endpoints[index])
            }
            let remove = endpointRowAction(tableView, title: "Remove") {
                (index: Int) -> Void in
                // TODO make EndpointsService with operations on endpoints, then listen for endpointsChanged events and react instead
                self.endpoints.remove(at: index)
                self.settings.saveAll(self.endpoints)
                let visualIndex = IndexPath(row: index + 1, section: 0)
                tableView.deleteRows(at: [visualIndex], with: UITableViewRowAnimation.fade)
            }
            return [edit, remove]
        }
        // "this device" is not editable
        return []
    }
    
    func endpointRowAction(_ tableView: UITableView, title: String, f: @escaping (Int) -> Void) -> UITableViewRowAction {
        return UITableViewRowAction(style: UITableViewRowActionStyle.default, title: title) {
            (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            let endIndex = (indexPath as NSIndexPath).row - 1
            if endIndex >= 0 && self.endpoints.count > endIndex {
                f(endIndex)
            }
            tableView.setEditing(false, animated: true)
        }
    }
}
