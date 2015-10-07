//
//  CacheTableController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 04/07/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class CacheTableController: CacheInfoController {
    
    static let CacheEnabledCell = "CacheEnabledCell", CacheSizeCell = "CacheSizeCell", DeleteCacheCell = "DeleteCacheCell"
    
    var onOffSwitch: UISwitch? = nil
    
    @IBOutlet var currentLimitLabel: UILabel!
    
    @IBOutlet var currentCacheSizeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let onOff = UISwitch(frame: CGRect.zero)
        onOff.addTarget(self, action: Selector("didToggleCache:"), forControlEvents: UIControlEvents.ValueChanged)
        onOff.on = settings.cacheEnabled
        onOffSwitch = onOff
        currentLimitLabel.text = currentLimitDescription
        updateCacheUsageLabel()
    }
    
    override func onCacheLimitChanged(newSize: StorageSize) {
        info("Got \(newSize)")
        Util.onUiThread {
            self.currentLimitLabel.text = self.currentLimitDescription
        }
        //renderTable()
    }
    
    private func updateCacheUsageLabel() {
        currentCacheSizeLabel.text = LocalLibrary.sharedInstance.size.shortDescription
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let reuse = cell.reuseIdentifier {
            switch reuse {
                case CacheTableController.CacheEnabledCell:
                cell.accessoryView = onOffSwitch
                break
            case CacheTableController.CacheSizeCell:
                //currentLimitLabel.text = currentLimitDescription
                break
            case CacheTableController.DeleteCacheCell:
                
                break
            default:
                break
            }
        }
        return cell
    }
    
    func didToggleCache(uiSwitch: UISwitch) {
        let isOn = uiSwitch.on
        settings.cacheEnabled = isOn
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if let reuseIdentifier = cell?.reuseIdentifier {
            switch reuseIdentifier {
            case CacheTableController.DeleteCacheCell:
                deleteCache()
                break
            default:
                break
            }
        }
    }
    private func deleteCache() {
        LocalLibrary.sharedInstance.deleteContents()
        updateCacheUsageLabel()
    }
}