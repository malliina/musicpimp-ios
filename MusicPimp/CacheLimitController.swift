//
//  CacheLimitController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 05/07/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class CacheLimitController: BaseTableController {
    let gigOptions: [Int] = [1, 2, 5, 10, 20, 50, 100, 500]
    var sizes: [StorageSize] { get { return gigOptions.map { (gB) -> StorageSize in return StorageSize(gigs: gB) } } }
    var current: StorageSize { return settings.cacheLimit }
    
    override func viewDidLoad() {
        settings.cacheLimitChanged.addHandler(self) { (clf) -> (StorageSize) -> () in
            clf.onCacheLimitChanged
        }
    }
    
    func onCacheLimitChanged(_ newLimit: StorageSize) {
        renderTable()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = (indexPath as NSIndexPath).row
        let cellGigs = gigOptions[row]
        let cellSize = sizes[row]
        let prototype = cellSize == current ? "CurrentCacheLimit" : "CacheLimit"
        let cell = tableView.dequeueReusableCell(withIdentifier: prototype, for: indexPath) 
        cell.textLabel?.text = "\(cellGigs) GB"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let size = sizes[(indexPath as NSIndexPath).row]
        settings.cacheLimit = size
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gigOptions.count
    }
}
