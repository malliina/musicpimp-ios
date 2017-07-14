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
    let currentCacheCell = "CurrentCacheLimit"
    let cacheCell = "CacheLimit"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let _ = settings.cacheLimitChanged.addHandler(self) { (clf) -> (StorageSize) -> () in
            clf.onCacheLimitChanged
        }
        [currentCacheCell, cacheCell].forEach { (id) in
            registerCell(reuseIdentifier: id)
        }
    }
    
    func onCacheLimitChanged(_ newLimit: StorageSize) {
        renderTable()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cellGigs = gigOptions[row]
        let cellSize = sizes[row]
        let isCurrent = cellSize == current
        let prototype = isCurrent ? currentCacheCell : cacheCell
        let accessory = isCurrent ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        let cell = tableView.dequeueReusableCell(withIdentifier: prototype, for: indexPath)
        cell.accessoryType = accessory
        cell.textLabel?.tintColor = PimpColors.titles
        cell.textLabel?.textColor = PimpColors.titles
        cell.textLabel?.text = "\(cellGigs) GB"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let size = sizes[indexPath.row]
        settings.cacheLimit = size
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gigOptions.count
    }
}
