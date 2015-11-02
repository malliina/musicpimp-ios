//
//  EditEndpointController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class EditEndpointController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var typeControl: UISegmentedControl!
    @IBOutlet var nameField: UITextField!
    @IBOutlet var addressField: UITextField!
    @IBOutlet var portField: UITextField!
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var protocolControl: UISegmentedControl!
    @IBOutlet var portLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var cloudIDField: UITextField!
    @IBOutlet var cloudIDLabel: UILabel!
    @IBOutlet var feedbackText: UITextView!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var segueID: String? = nil
    var editedItem: Endpoint? = nil
    
    override func viewDidLoad() {
        let textFields = [nameField, addressField, portField, usernameField, passwordField, cloudIDField]
        textFields.forEach { (elem) -> () in
            elem.delegate = self
        }
        if let editedItem = editedItem {
            fill(editedItem)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(sender as? UIBarButtonItem != saveButton) {
            return
        }
        if let endpoint = parseEndpoint() {
            //info("Save \(endpoint)")
            PimpSettings.sharedInstance.save(endpoint)
        }
    }
    
    @IBAction func serverTypeChanged(sender: UISegmentedControl) {
        if let serverType = readServerType(sender) {
            adjustVisibility(serverType)
        }
    }
    
    @IBAction func testClicked(sender: AnyObject) {
        if let endpoint = parseEndpoint() {
            info("Testing \(endpoint.httpBaseUrl)")
            feedback("Connecting...")
            let client = Libraries.fromEndpoint(endpoint)
            client.pingAuth(
                {(err) in self.onTestFailure(endpoint, error: err) },
                f: {(v) in self.onTestSuccess(endpoint, v: v) })
        } else {
            feedback("Please ensure that all the fields are filled in properly.")
        }
    }

    private func adjustVisibility(serverType: ServerType) {
        let cloudViews = [cloudIDLabel, cloudIDField]
        let nonCloudViews = [nameLabel, nameField, addressLabel, addressField, portLabel, portField, protocolControl]
        let cloudVisible = serverType.name == ServerTypes.Cloud.name
        for cloudView in cloudViews {
            cloudView.hidden = !cloudVisible
        }
        for nonCloudView in nonCloudViews {
            nonCloudView.hidden = cloudVisible
        }
    }
    
    func onTestSuccess(e: Endpoint, v: Version) {
        let server = e.serverType.name
        feedback("\(server) \(v.version) at your service.")
    }
    
    func onTestFailure(e: Endpoint, error: PimpError) {
        let msg = errorMessage(e, error: error)
        Log.info("Test failed: \(msg)")
        feedback(msg)
    }
    
    func errorMessage(e: Endpoint, error: PimpError) -> String {
        switch error {
            case PimpError.ResponseFailure( _, let code, _):
                switch code {
                    case 401: return "Unauthorized. Check your username/password."
                    default: return "HTTP error code \(code)."
                }
            case PimpError.NetworkFailure( _):
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
        let serverType = e.serverType
        adjustVisibility(serverType)
        typeControl.selectedSegmentIndex = serverType.index
        if serverType.name == ServerTypes.Cloud.name {
            cloudIDField.text = e.name
        } else {
            nameField.text = e.name
        }
        addressField.text = e.address
        portField.text = String(e.port)
        usernameField.text = e.username
        passwordField.text = e.password
        let protoIndex = e.ssl ? 1 : 0
        protocolControl.selectedSegmentIndex = protoIndex
    }

    func readServerType(control: UISegmentedControl) -> ServerType? {
        return ServerTypes.fromIndex(control.selectedSegmentIndex)
    }
    
    func parseEndpoint() -> Endpoint? {
        let id = editedItem?.id ?? NSUUID().UUIDString
        if let serverType = readServerType(typeControl) {
            if serverType.name == ServerTypes.Cloud.name {
                let existsEmpty = [cloudIDField, usernameField, passwordField].exists({ $0.text!.isEmpty })
                if existsEmpty {
                    return nil
                }
                return Endpoint(id: id, cloudID: cloudIDField.text!, username: usernameField.text!, password: passwordField.text!)
            } else {
                if let portText = portField.text, port = Int(portText) {
                    let protoIndex = protocolControl.selectedSegmentIndex
                    let ssl = protoIndex == 1
                    let existsEmpty = [nameField, addressField, portField, usernameField, passwordField].exists({ $0.text!.isEmpty })
                    if existsEmpty {
                        return nil
                    }
                    return Endpoint(id: id, serverType: serverType, name: nameField.text!, ssl: ssl, address: addressField.text!, port: port, username: usernameField.text!, password: passwordField.text!)
                }
            }
        }
        return nil
    }
    
    func info(s: String) {
        Log.info(s)
    }

}
