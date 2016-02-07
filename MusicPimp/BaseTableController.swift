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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func renderTable(feedback: String? = nil) {
        Util.onUiThread {
            if let feedback = feedback {
                self.setFeedback(feedback)
            } else {
                self.clearFeedback()
            }
            self.tableView.reloadData()
        }
    }
    
    func setFeedback(feedback: String) {
        self.tableView.backgroundView = self.feedbackLabel(feedback)
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    }
    
    func clearFeedback() {
        self.tableView.backgroundView = nil
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
    }
    
    func feedbackLabel(text: String) -> UILabel {
        let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        let label = FeedbackLabel(frame: frame)
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .Center
        return label
    }
    
    func info(s: String) {
        Log.info(s)
    }
    
    func error(e: String) {
        Log.error(e)
    }
    
    func onError(pimpError: PimpError) {
        let message = PimpErrorUtil.stringify(pimpError)
        error(message)
    }
}
