//
//  SavePlaylistViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class SavePlaylistViewController: PimpViewController, UITextFieldDelegate {
    
    @IBOutlet var nameText: UITextField!
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
//        self.navigationController?.popViewControllerAnimated(true)
        dismiss(animated: true, completion: nil)
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
        nameText.addTarget(self, action: #selector(SavePlaylistViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sender = sender as? UIBarButtonItem, saveButton === sender {
            name = nameText.text ?? ""
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let sender = sender as? UIBarButtonItem, saveButton === sender {
            let name = nameText.text ?? ""
            return !name.isEmpty
        } else {
            return true
        }
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        checkValidName()
    }
    
    func checkValidName() {
        let text = nameText.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameText.resignFirstResponder()
        return true
    }
}
