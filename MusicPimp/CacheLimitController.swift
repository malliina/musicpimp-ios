//
//  CacheLimitController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 05/07/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class CacheLimitController: BaseTableController {
    let gigOptions: [UInt] = [1, 2, 5, 10, 20, 50, 100, 500]
    var sizes: [StorageSize] { get { return gigOptions.map { (gB) -> StorageSize in return StorageSize(gigs: gB) } } }
    var current: StorageSize { return settings.cacheLimit }
    
    override func viewDidLoad() {
        settings.cacheLimitChanged.addHandler(self, handler: { (clf) -> StorageSize -> () in
            clf.onCacheLimitChanged
        })
    }
    private func onCacheLimitChanged(newLimit: StorageSize) {
        renderTable()
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cellGigs = gigOptions[row]
        let cellSize = sizes[row]
        let prototype = cellSize == current ? "CurrentCacheLimit" : "CacheLimit"
        let cell = tableView.dequeueReusableCellWithIdentifier(prototype, forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = "\(cellGigs) GB"
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let size = sizes[indexPath.row]
        settings.cacheLimit = size
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gigOptions.count
    }
}
