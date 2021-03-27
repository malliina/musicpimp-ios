//
//  CacheTableController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 04/07/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

class CacheTableController: CacheInfoController {
    private let log = LoggerFactory.shared.pimp(CacheTableController.self)
    
    let CacheEnabledCell = "CacheEnabledCell", CacheSizeCell = "CacheSizeCell", CurrentUsageCell = "CurrentUsageCell", DeleteCacheCell = "DeleteCacheCell", DeleteCustom = "DeleteCustom", EmptyCell = "EmptyCell"
    
    let onOffSwitch = UISwitch(frame: CGRect.zero)

    let sectionFooterIdentifier = "SectionFooter"
    static let footerText = "Deletes locally cached tracks when the specified cache size limit is exceeded."
    let headerLabel = PimpLabel.footerLabel(CacheTableController.footerText)
    
    var footerInset: CGFloat { get { tableView.layoutMargins.left } }
    
    var library: LocalLibrary { LocalLibrary.sharedInstance }
    
    let disposeBag = DisposeBag()
    let usedStorage = BehaviorSubject<StorageSize>(value: StorageSize.Zero)
    private var latestStorage: StorageSize = StorageSize.Zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "OFFLINE STORAGE"
        [CacheEnabledCell, CurrentUsageCell, DeleteCacheCell].forEach { id in
            self.tableView?.register(DetailedCell.self, forCellReuseIdentifier: id)
        }
        self.tableView?.register(DisclosureCell.self, forCellReuseIdentifier: CacheSizeCell)
        [DeleteCustom, EmptyCell].forEach { (id) in
            registerCell(reuseIdentifier: id)
        }
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: sectionFooterIdentifier)
        onOffSwitch.addTarget(self, action: #selector(CacheTableController.didToggleCache(_:)), for: UIControl.Event.valueChanged)
        onOffSwitch.isOn = settings.cacheEnabled
        usedStorage.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { (size) in
            self.latestStorage = size
            self.tableView.reloadData()
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
        calculateCacheUsage()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: self.tableView, animation: nil) { _ in
            self.headerLabel.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(self.footerInset)
            }
            self.tableView.reloadData()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
    
    override func onCacheLimitChanged(_ newSize: StorageSize) {
        log.info("Updating cache limit UI to \(newSize)")
        Util.onUiThread {
            self.tableView.reloadData()
        }
    }
    
    fileprivate func calculateCacheUsage() {
        DispatchQueue.global(qos: .background).async {
            self.usedStorage.onNext(self.library.size)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let spec = specForRow(indexPath: indexPath) ?? RowSpec(reuseIdentifier: EmptyCell, text: "")
        switch spec.reuseIdentifier {
        case CacheEnabledCell:
            let cell = basicCell(spec: spec, indexPath: indexPath)
            cell.accessoryView = onOffSwitch
            return cell
        case CacheSizeCell:
            let cell: DisclosureCell = loadCell(spec.reuseIdentifier, index: indexPath)
            cell.title.text = spec.text
            cell.detail.text = currentLimitDescription
            return cell
        case CurrentUsageCell:
            let cell = basicCell(spec: spec, indexPath: indexPath)
            cell.detailTextLabel?.text = latestStorage.shortDescription
            return cell
        case DeleteCustom:
            let cell = basicCell(spec: spec, indexPath: indexPath)
            if let label = cell.textLabel {
                label.textColor = colors.deletion
                label.textAlignment = .center
                label.highlightedTextColor = colors.deletionHighlighted
            }
            return cell
        default:
            return identifiedCell(EmptyCell, index: indexPath)
        }
    }
    
    func basicCell(spec: RowSpec, indexPath: IndexPath) -> UITableViewCell {
        let cell = identifiedCell(spec.reuseIdentifier, index: indexPath)
        cell.textLabel?.text = spec.text
        cell.textLabel?.textColor = colors.titles
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
            case 0: return RowSpec(reuseIdentifier: CacheSizeCell, text: "Size Limit")
            case 1: return RowSpec(reuseIdentifier: CurrentUsageCell, text: "Current Usage")
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
        case 1: return 2
        case 2: return 1
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return footerView(identifier: sectionFooterIdentifier, content: headerLabel)
        } else {
            return super.tableView(tableView, viewForFooterInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let v = view as? UITableViewHeaderFooterView {
            v.tintColor = colors.background
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        headerLabel.tableHeaderHeight(tableView)
    }
    
    @objc func didToggleCache(_ uiSwitch: UISwitch) {
        let isOn = uiSwitch.isOn
        settings.cacheEnabled = isOn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
//        tableView.deselectRow(at: indexPath, animated: false)
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
        let _ = library.deleteContents().subscribe { (bool) in
            self.log.info("Done")
            self.calculateCacheUsage()
        } onFailure: { (err) in
            self.log.info("Failed to delete contents: '\(err)'.")
        } onDisposed: {
            ()
        }
    }
}

extension UITableViewController {
    func footerView(identifier: String, content: UILabel) -> UITableViewHeaderFooterView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier)
        content.autoresizingMask = .flexibleHeight
        view?.contentView.addSubview(content)
        content.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(tableView.layoutMargins.left)
            make.topMargin.equalToSuperview().offset(PimpLabel.headerTopMargin)
        }
        view?.contentView.backgroundColor = PimpColors.shared.background
        return view
    }
}
