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
    
    func registerNib(nameAndIdentifier: String) {
        self.tableView.registerNib(UINib(nibName: nameAndIdentifier, bundle: nil), forCellReuseIdentifier: nameAndIdentifier)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func renderTable(feedback: String? = nil) {
        onUiThread {
            if let feedback = feedback {
                self.setFeedback(feedback)
            } else {
                self.clearFeedback()
            }
            self.tableView.reloadData()
        }
    }
    
    func onUiThread(code: () -> Void) {
        Util.onUiThread(code)
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
        // makes no difference afaik, used in a backgroundView so its size is the same as that of the table
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
    func limitChecked<T>(code: () -> T) -> T? {
        if Limiter.sharedInstance.isWithinLimit() {
            return code()
        } else {
            suggestPremium()
            return nil
        }
    }
    
    func suggestPremium() {
        let sheet = UIAlertController(title: IAPConstants.Title, message: IAPConstants.Message, preferredStyle: UIAlertControllerStyle.Alert)
        let premiumAction = UIAlertAction(title: IAPConstants.OkText, style: UIAlertActionStyle.Default) { a -> Void in
            Log.info("Purchase premium")
            if let storyboard = self.storyboard {
                let destination = storyboard.instantiateViewControllerWithIdentifier(IAPViewController.StoryboardId)
//                let navigationController = UINavigationController(rootViewController: destination)
//                self.presentViewController(navigationController, animated: true, completion: nil)
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
        let notInterestedAction = UIAlertAction(title: IAPConstants.CancelText, style: UIAlertActionStyle.Cancel) { a -> Void in
            Log.info("Not interested")
        }
        sheet.addAction(premiumAction)
        sheet.addAction(notInterestedAction)
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = self.view
        }
        self.presentViewController(sheet, animated: true, completion: nil)
    }
}