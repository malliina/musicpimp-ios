//
//  SavePlaylistViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class SavePlaylistViewController: UIViewController {
    @IBOutlet var nameText: UITextField!
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBOutlet var saveButton: UIBarButtonItem!
    
    var name: String?
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if saveButton === sender {
            name = nameText.text ?? ""
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if saveButton === sender {
            let name = nameText.text ?? ""
            return !name.isEmpty
        } else {
            return true
        }
    }
}
