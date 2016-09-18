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
        onOff.addTarget(self, action: #selector(CacheTableController.didToggleCache(_:)), for: UIControlEvents.valueChanged)
        onOff.isOn = settings.cacheEnabled
        onOffSwitch = onOff
        currentLimitLabel.text = currentLimitDescription
        updateCacheUsageLabel()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func onCacheLimitChanged(_ newSize: StorageSize) {
        Util.onUiThread {
            self.currentLimitLabel.text = self.currentLimitDescription
        }
        //renderTable()
    }
    
    fileprivate func updateCacheUsageLabel() {
        currentCacheSizeLabel.text = LocalLibrary.sharedInstance.size.shortDescription
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let reuse = cell.reuseIdentifier {
            switch reuse {
                case CacheTableController.CacheEnabledCell:
                cell.accessoryView = onOffSwitch
                break
            case CacheTableController.CacheSizeCell:
                //currentLimitLabel.text = currentLimitDescription
                break
            case CacheTableController.DeleteCacheCell:
                cell.textLabel?.textColor = PimpColors.deletion
                break
            default:
                break
            }
        }
        return cell
    }
    
    func didToggleCache(_ uiSwitch: UISwitch) {
        let isOn = uiSwitch.isOn
        settings.cacheEnabled = isOn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
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
    fileprivate func deleteCache() {
        LocalLibrary.sharedInstance.deleteContents()
        updateCacheUsageLabel()
    }
}
