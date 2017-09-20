//
//  BaseTableController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 14/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class BaseTableController: UITableViewController {
    let settings = PimpSettings.sharedInstance
    
    let limiter = Limiter.sharedInstance
    var currentFeedback: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // The background color when there are no more rows
        self.view.backgroundColor = PimpColors.background
        // Removes separators when there are no more rows
        self.tableView.tableFooterView = UIView()
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.font: PimpColors.titleFont
        ]
        // Does not add margins to table cells on iPad Pro+
        self.tableView.cellLayoutMarginsFollowReadableWidth = false
    }
    
    func registerCell(reuseIdentifier: String) {
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    func loadCell<T>(_ name: String, index: IndexPath) -> T {
        return findCell(name, index: index)!
    }
    
    func findCell<T>(_ name: String, index: IndexPath) -> T? {
        return identifiedCell(name, index: index) as? T
    }
    
    func identifiedCell(_ name: String, index: IndexPath) -> UITableViewCell {
        return self.tableView.dequeueReusableCell(withIdentifier: name, for: index)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func renderTable(_ feedback: String? = nil) {
        renderTable(feedback) { () }
    }
    
    func renderTable(_ feedback: String?, _ afterData: @escaping () -> Void) {
        onUiThread {
            if let feedback = feedback {
                self.setFeedback(feedback)
            } else {
                self.clearFeedback()
            }
            self.tableView.reloadData()
            afterData()
        }
    }
    
    func onUiThread(_ code: @escaping () -> Void) {
        Util.onUiThread(code)
    }
    
    func setFeedback(_ feedback: String) {
        currentFeedback = feedback
        configureTable(background: self.feedbackLabel(feedback), separatorStyle: UITableViewCellSeparatorStyle.none)
    }
    
    func clearFeedback() {
        currentFeedback = nil
        configureTable(background: nil, separatorStyle: UITableViewCellSeparatorStyle.singleLine)
    }
    
    func configureTable(background: UIView?, separatorStyle: UITableViewCellSeparatorStyle) {
        self.tableView.backgroundView = background
        self.tableView.separatorStyle = separatorStyle
    }
    
    func customFooter(_ text: String) -> UIView {
        let content = UIView()
        let label = PimpLabel.footerLabel(text)
        content.addSubview(label)
        label.snp.makeConstraints{ make in
            make.leading.trailing.equalToSuperview().inset(16)
        }
        return content
    }
    
    func feedbackLabel(_ text: String) -> UILabel {
        // makes no difference afaik, used in a backgroundView so its size is the same as that of the table
        let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        let label = FeedbackLabel(frame: frame)
        label.textColor = PimpColors.titles
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }
    
    func onError(_ pimpError: PimpError) {
        Util.onError(pimpError)
    }
    
}

class IAPConstants {
    static let Title = "Limit reached"
    static let Message = "The free version of this app lets you play a couple of tracks per day. A one-time purchase unlocks MusicPimp Premium which enables unlimited playback."
    static let OkText = "Get Premium"
    static let CancelText = "Not interested"
}

extension UIViewController {
    func limitChecked<T>(_ code: () -> T) -> T? {
        if Limiter.sharedInstance.isWithinLimit() {
            return code()
        } else {
            suggestPremium()
            return nil
        }
    }
    
    func suggestPremium() {
        let sheet = UIAlertController(title: IAPConstants.Title, message: IAPConstants.Message, preferredStyle: UIAlertControllerStyle.alert)
        let premiumAction = UIAlertAction(title: IAPConstants.OkText, style: UIAlertActionStyle.default) { a -> Void in
            self.navigationController?.pushViewController(IAPViewController(), animated: true)
        }
        let notInterestedAction = UIAlertAction(title: IAPConstants.CancelText, style: UIAlertActionStyle.cancel) { a -> Void in
        }
        sheet.addAction(premiumAction)
        sheet.addAction(notInterestedAction)
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = self.view
        }
        self.present(sheet, animated: true, completion: nil)
    }
}
