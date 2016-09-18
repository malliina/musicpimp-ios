//
//  EditEndpointController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class EditEndpointController: PimpViewController, UITextFieldDelegate {
    
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
    @IBOutlet var activateSwitch: UISwitch!
    @IBOutlet var feedbackText: UITextView!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var segueID: String? = nil
    var editedItem: Endpoint? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let textFields = [nameField, addressField, portField, usernameField, passwordField, cloudIDField]
        textFields.forEach { (elem) -> () in
            elem?.delegate = self
        }
        if let editedItem = editedItem {
            fill(editedItem)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sender = sender as? UIBarButtonItem, saveButton === sender {
            saveChanges()
        }
    }
    
    func saveChanges() {
        if let endpoint = parseEndpoint() {
            PimpSettings.sharedInstance.save(endpoint)
            if activateSwitch.isOn {
                Log.info("Activating \(endpoint.name)")
                LibraryManager.sharedInstance.saveActive(endpoint)
            }
        }
    }
    
    @IBAction func serverTypeChanged(_ sender: UISegmentedControl) {
        if let serverType = readServerType(sender) {
            adjustVisibility(serverType)
        }
    }
    
    @IBAction func testClicked(_ sender: AnyObject) {
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

    fileprivate func adjustVisibility(_ serverType: ServerType) {
        let cloudViews: [UIView] = [cloudIDLabel, cloudIDField]
        let nonCloudViews: [UIView] = [nameLabel, nameField, addressLabel, addressField, portLabel, portField, protocolControl]
        let cloudVisible = serverType.name == ServerTypes.Cloud.name
        for cloudView in cloudViews {
            cloudView.isHidden = !cloudVisible
        }
        for nonCloudView in nonCloudViews {
            nonCloudView.isHidden = cloudVisible
        }
    }
    
    func onTestSuccess(_ e: Endpoint, v: Version) {
        let server = e.serverType.name
        feedback("\(server) \(v.version) at your service.")
    }
    
    func onTestFailure(_ e: Endpoint, error: PimpError) {
        let msg = errorMessage(e, error: error)
        Log.info("Test failed: \(msg)")
        feedback(msg)
    }
    
    func errorMessage(_ e: Endpoint, error: PimpError) -> String {
        switch error {
            case PimpError.responseFailure(let details):
                let code = details.code
                switch code {
                    case 401: return "Unauthorized. Check your username/password."
                    default: return "HTTP error code \(code)."
                }
            case PimpError.networkFailure( _):
                return "Unable to connect to \(e.httpBaseUrl)."
            case PimpError.parseError:
                return "The response was not understood."
            case .simpleError(let message):
                return message.message
        }
    }
    
    func feedback(_ f: String) {
        Util.onUiThread {
            self.feedbackText.text = f
            self.feedbackText.font = UIFont.systemFont(ofSize: 16)
            self.feedbackText.textColor = PimpColors.titles
        }
    }
    
    func fill(_ e: Endpoint) {
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

    func readServerType(_ control: UISegmentedControl) -> ServerType? {
        return ServerTypes.fromIndex(control.selectedSegmentIndex)
    }
    
    func parseEndpoint() -> Endpoint? {
        let id = editedItem?.id ?? UUID().uuidString
        if let serverType = readServerType(typeControl) {
            if serverType.name == ServerTypes.Cloud.name {
                let existsEmpty = [cloudIDField, usernameField, passwordField].exists({ $0.text!.isEmpty })
                if existsEmpty {
                    return nil
                }
                return Endpoint(id: id, cloudID: cloudIDField.text!, username: usernameField.text!, password: passwordField.text!)
            } else {
                if let portText = portField.text, let port = Int(portText) {
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
    
    func info(_ s: String) {
        Log.info(s)
    }

}
