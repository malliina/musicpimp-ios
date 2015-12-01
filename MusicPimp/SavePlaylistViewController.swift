//
//  SavePlaylistViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class SavePlaylistViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var nameText: UITextField!
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        Log.info("Cancel")
//        self.navigationController?.popViewControllerAnimated(true)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBOutlet var saveButton: UIBarButtonItem!
    
    var name: String?
    
    override func viewDidLoad() {
        if let name = name {
            nameText.text = name
        }
        super.viewDidLoad()
        nameText.delegate = self
        checkValidName()
        nameText.addTarget(self, action: Selector("textFieldDidChange:"), forControlEvents: UIControlEvents.EditingChanged)
    }
    
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
    
    func textFieldDidChange(textField: UITextField) {
        checkValidName()
    }
    
    func checkValidName() {
        let text = nameText.text ?? ""
        saveButton.enabled = !text.isEmpty
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        nameText.resignFirstResponder()
        return true
    }
}
