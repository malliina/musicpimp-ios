//
//  EditAlarmController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class EditAlarmController: UIViewController {
    var editedAlarm: Alarm? = nil
    
    @IBOutlet var saveButton: UIBarButtonItem!
    
    @IBAction func cancel(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func save(sender: UIBarButtonItem) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if saveButton === sender {
            
        }
    }
}
