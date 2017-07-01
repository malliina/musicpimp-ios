//
//  CacheTableController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 04/07/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class CacheTableController: CacheInfoController {
    
    let CacheEnabledCell = "CacheEnabledCell", CacheSizeCell = "CacheSizeCell", CurrentUsageCell = "CurrentUsageCell", DeleteCacheCell = "DeleteCacheCell", DeleteCustom = "DeleteCustom", EmptyCell = "EmptyCell"
    
    let onOffSwitch = UISwitch(frame: CGRect.zero)
    let currentLimitLabel = UILabel()
    let currentCacheSizeLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        [CacheEnabledCell, CacheSizeCell, CurrentUsageCell, DeleteCacheCell].forEach { id in
            self.tableView?.register(DetailedCell.self, forCellReuseIdentifier: id)
        }
        [DeleteCustom, EmptyCell].forEach { (id) in
            registerCell(reuseIdentifier: id)
        }
        onOffSwitch.addTarget(self, action: #selector(CacheTableController.didToggleCache(_:)), for: UIControlEvents.valueChanged)
        onOffSwitch.isOn = settings.cacheEnabled
        currentLimitLabel.text = currentLimitDescription
        updateCacheUsageLabel()
        Log.info("Loaded")
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
        Log.info("Current usage: \(LocalLibrary.sharedInstance.size.shortDescription)")
        currentCacheSizeLabel.text = LocalLibrary.sharedInstance.size.shortDescription
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let spec = specForRow(indexPath: indexPath) ?? RowSpec(reuseIdentifier: EmptyCell, text: "")
        let cell = identifiedCell(spec.reuseIdentifier, index: indexPath)
        cell.textLabel?.text = spec.text
        cell.textLabel?.textColor = PimpColors.titles
        switch spec.reuseIdentifier {
        case CacheEnabledCell:
            cell.accessoryView = onOffSwitch
            break
        case CacheSizeCell:
            cell.accessoryType = .disclosureIndicator
            cell.detailTextLabel?.text = currentLimitLabel.text
            break
        case CurrentUsageCell:
            cell.detailTextLabel?.text = currentCacheSizeLabel.text
            break
        case DeleteCustom:
            cell.textLabel?.textColor = PimpColors.deletion
//            cell.textLabel?.tintColor = PimpColors.deletion
            cell.textLabel?.textAlignment = .center
            break
        default:
            break
        }
        return cell
    }
    
    func specForRow(indexPath: IndexPath) -> RowSpec? {
        let row = indexPath.row
        switch indexPath.section {
        case 0:
            switch row {
            case 0: return RowSpec(reuseIdentifier: CacheEnabledCell, text: "Automatic Offline Storage")
            default: return nil
            }
        case 1:
            switch row {
            case 1: return RowSpec(reuseIdentifier: CacheSizeCell, text: "Size Limit")
            case 2: return RowSpec(reuseIdentifier: CurrentUsageCell, text: "Current Usage")
            default: return nil
            }
        case 2:
            switch row {
            case 0: return RowSpec(reuseIdentifier: DeleteCustom, text: "Delete Offline Storage")
            default: return nil
            }
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 4
        case 2: return 1
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Deletes locally cached tracks when the specified cache size limit is exceeded."
        } else {
            return nil
        }
    }
    
    func didToggleCache(_ uiSwitch: UISwitch) {
        let isOn = uiSwitch.isOn
        settings.cacheEnabled = isOn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: false)
        if let reuseIdentifier = cell?.reuseIdentifier {
            switch reuseIdentifier {
            case CacheSizeCell:
                self.navigationController?.pushViewController(CacheLimitController(), animated: true)
            case DeleteCustom:
                deleteCache()
                break
            default:
                break
            }
        }
    }
    fileprivate func deleteCache() {
        let _ = LocalLibrary.sharedInstance.deleteContents()
        updateCacheUsageLabel()
    }
}
