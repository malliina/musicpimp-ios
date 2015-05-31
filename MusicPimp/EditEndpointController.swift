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
    
    var editedItem: Endpoint? = nil
    
    override func viewDidLoad() {
        if let editedItem = editedItem {
            fill(editedItem)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(sender as? UIBarButtonItem != saveButton) {
            return
        }
        if let endpoint = parseEndpoint() {
            info("Save \(endpoint)")
            PimpSettings.sharedInstance.save(endpoint)
        }
    }
    
    @IBAction func testClicked(sender: AnyObject) {
        info("Testing...")
        if let endpoint = parseEndpoint() {
            feedback("Connecting...")
            let client = Libraries.fromEndpoint(endpoint)// PimpHttpClient(endpoint: endpoint)
            client.pingAuth(
                {(err) in self.onTestFailure(endpoint, error: err) },
                f: {(v) in self.onTestSuccess(endpoint, v: v) })
        } else {
            feedback("Please ensure that all the fields are filled in properly.")
        }
    }
    func onTestSuccess(e: Endpoint, v: Version) {
        let server = e.serverType.rawValue
        feedback("\(server) \(v.version) at your service.")
    }
    func onTestFailure(e: Endpoint, error: PimpError) {
        feedback(errorMessage(e, error: error))
    }
    func errorMessage(e: Endpoint, error: PimpError) -> String {
        switch error {
            case PimpError.ResponseFailure(let code, let message):
                switch code {
                    case 401: return "Unauthorized. Check your username/password."
                    default: return "HTTP error code \(code)"
                }
            case PimpError.NetworkFailure(let req):
                return "Unable to connect to \(e.httpBaseUrl)."
            case PimpError.ParseError:
                return "The response was not understood."
            case .SimpleError(let message):
                return message.message
        }
    }
    
    func feedback(f: String) {
        Util.onUiThread {
            self.feedbackText.text = f
        }
    }
    
    func fill(e: Endpoint) {
        let typeIndex = e.serverType == .MusicPimp ? 0 : 1
        typeControl.selectedSegmentIndex = typeIndex
        nameField.text = e.name
        addressField.text = e.address
        portField.text = String(e.port)
        usernameField.text = e.username
        passwordField.text = e.password
        let protoIndex = e.ssl ? 1 : 0
        protocolControl.selectedSegmentIndex = protoIndex
    }

    func parseEndpoint() -> Endpoint? {
        let endTypeIndex = typeControl.selectedSegmentIndex
        let serverType: ServerType = endTypeIndex == 0 ? .MusicPimp : .Subsonic
        let protoIndex = protocolControl.selectedSegmentIndex
        let ssl = protoIndex == 1
//        let proto: Protocol = protoIndex == 0 ? .Http : .Https // Protocol(rawValue: protoIndex) ?? .Https
        let existsEmpty = [nameField, addressField, portField, usernameField, passwordField].exists({ $0.text.isEmpty })
        let port = portField.text.toInt()
        if existsEmpty || port == nil {
            return nil
        }
        if let port = port {
            var id = editedItem?.id ?? NSUUID().UUIDString
            return Endpoint(id: id, serverType: serverType, name: nameField.text, ssl: ssl, address: addressField.text, port: port, username: usernameField.text, password: passwordField.text)
        }
        return nil
        
    }
    
    func info(s: String) {
        Log.info(s)
    }

}
