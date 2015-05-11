//
//  EditEndpointController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class EditEndpointController: UIViewController {
    
    @IBOutlet var typeControl: UISegmentedControl!
    @IBOutlet var nameField: UITextField!
    @IBOutlet var addressField: UITextField!
    @IBOutlet var portField: UITextField!
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var protocolControl: UISegmentedControl!
    
    @IBOutlet var feedbackText: UITextView!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(sender as? UIBarButtonItem != saveButton) {
            return
        }
        if let endpoint = parseEndpoint() {
            info("Save \(endpoint)")
            JsonIO.sharedInstance.save(endpoint)
        }
    }
    
    @IBAction func testClicked(sender: AnyObject) {
        info("Testing...")
        let endpoint = parseEndpoint()
        if let endpoint = endpoint {
            feedbackText.text = "Connecting..."
            feedbackText.text = "Woohoo!"
            let json = PimpJson.sharedInstance
            let asJson = json.jsonStringified(endpoint) ?? "Invalid JSON"
            info(asJson)
        } else {
            feedbackText.text = "Please ensure that all the fields are filled in properly."
        }
    }
    
    func parseEndpoint() -> Endpoint? {
        let endTypeIndex = typeControl.selectedSegmentIndex
        let serverType: ServerType = endTypeIndex == 0 ? .MusicPimp : .Subsonic
        let protoIndex = protocolControl.selectedSegmentIndex
        let proto: Protocol = protoIndex == 0 ? .Http : .Https // Protocol(rawValue: protoIndex) ?? .Https
        let existsEmpty = [nameField, addressField, portField, usernameField, passwordField].exists({ $0.text.isEmpty })
        let port = portField.text.toInt()
        if existsEmpty || port == nil {
            return nil
        }
        if let port = port {
            return Endpoint(id: "test", serverType: serverType, name: nameField.text, proto: proto, address: addressField.text, port: port, username: usernameField.text, password: passwordField.text)
        }
        return nil
        
    }
    
    func info(s: String) {
        Log.info(s)
    }

}
