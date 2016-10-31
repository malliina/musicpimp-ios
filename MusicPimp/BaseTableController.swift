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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // The background color when there are no more rows
        self.view.backgroundColor = PimpColors.background
        // Removes separators when there are no more rows
        self.tableView.tableFooterView = UIView()
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: PimpColors.titleFont
        ]
    }
    
    func registerNib(_ nameAndIdentifier: String) {
        self.tableView.register(UINib(nibName: nameAndIdentifier, bundle: nil), forCellReuseIdentifier: nameAndIdentifier)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func renderTable(_ feedback: String? = nil) {
        onUiThread {
            if let feedback = feedback {
                self.setFeedback(feedback)
            } else {
                self.clearFeedback()
            }
            self.tableView.reloadData()
        }
    }
    
    func onUiThread(_ code: @escaping () -> Void) {
        Util.onUiThread(code)
    }
    
    func setFeedback(_ feedback: String) {
        self.tableView.backgroundView = self.feedbackLabel(feedback)
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
    }
    
    func clearFeedback() {
        self.tableView.backgroundView = nil
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
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
    
    func info(_ s: String) {
        Log.info(s)
    }
    
    func error(_ e: String) {
        Log.error(e)
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
            Log.info("Purchase premium")
            if let storyboard = self.storyboard {
                let destination = storyboard.instantiateViewController(withIdentifier: IAPViewController.StoryboardId)
//                let navigationController = UINavigationController(rootViewController: destination)
//                self.presentViewController(navigationController, animated: true, completion: nil)
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
        let notInterestedAction = UIAlertAction(title: IAPConstants.CancelText, style: UIAlertActionStyle.cancel) { a -> Void in
            Log.info("Not interested")
        }
        sheet.addAction(premiumAction)
        sheet.addAction(notInterestedAction)
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = self.view
        }
        self.present(sheet, animated: true, completion: nil)
    }
}
