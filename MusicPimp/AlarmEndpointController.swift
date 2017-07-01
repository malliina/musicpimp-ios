//
//  AlarmEndpointController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 27/12/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class AlarmEndpointController: BaseTableController {
    
    let endpointIdentifier = "EndpointCell"
    
    var endpoints: [Endpoint] = []
    var selectedId: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        endpoints = settings.endpoints().filter { $0.supportsAlarms }
        selectedId = settings.defaultNotificationEndpoint()?.id
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return endpoints.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let endpoint = endpoints[index]
        let cell = tableView.dequeueReusableCell(withIdentifier: endpointIdentifier, for: indexPath)
        cell.textLabel?.text = endpoint.name
        let accessory = endpoint.id == selectedId ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        cell.accessoryType = accessory
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let endpoint = endpoints[indexPath.row]
        selectedId = endpoint.id
        settings.saveDefaultNotificationsEndpoint(endpoint)
        renderTable()
    }
}
