//
//  EditEndpointController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

fileprivate extension Selector {
    static let serverTypeChanged = #selector(EditEndpointController.serverTypeChanged(_:))
    static let testClicked = #selector(EditEndpointController.testClicked(_:))
}

class EditEndpointController: PimpViewController, UITextFieldDelegate {
    let scrollView = UIScrollView()
    let nameLabel = UILabel()
    let typeControl = UISegmentedControl()
    let nameField = UITextField()
    let addressField = UITextField()
    let portField = UITextField()
    let usernameLabel = UILabel()
    let usernameField = UITextField()
    let passwordLabel = UILabel()
    let passwordField = UITextField()
    let protocolControl = UISegmentedControl()
    let portLabel = UILabel()
    let addressLabel = UILabel()
    let cloudIDField = UITextField()
    let cloudIDLabel = UILabel()
    let activateSwitch = UISwitch()
    let feedbackText = UITextView()
    
    let saveButton = UIBarButtonItem()
    
    var segueID: String? = nil
    var editedItem: Endpoint? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        if let editedItem = editedItem {
            fill(editedItem)
        } else {
            updateVisibility(segment: typeControl)
        }
    }
    
    func initUI() {
        nameLabel.text = "Name"
        cloudIDLabel.text = "Cloud ID"
        addressLabel.text = "Address"
        portLabel.text = "Port"
        usernameLabel.text = "Username"
        passwordLabel.text = "Password"
        let textFields = [nameField, addressField, portField, usernameField, passwordField, cloudIDField]
        textFields.forEach { elem -> () in
            elem.delegate = self
        }
        let nonTextFields = [nameLabel, typeControl, protocolControl, portLabel, addressLabel, usernameLabel, passwordLabel, cloudIDLabel, activateSwitch, feedbackText]
        let views: [UIView] = nonTextFields + textFields
        views.forEach { inputView in
            scrollView.addSubview(inputView)
        }
        view.addSubview(scrollView)
        baseConstraints(views: [scrollView])
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(self.view.snp.topMargin).offset(8)
            make.bottom.equalTo(self.view.snp.bottomMargin).offset(-20)
        }
        typeControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
        }
        let fields = [typeControl, cloudIDLabel, cloudIDField, addressLabel, addressField, portLabel, portField, usernameLabel, usernameField, passwordLabel, passwordField, protocolControl]
        stack(views: fields)
        fields.forEach(leadingTrailingToSuper(target:))
        cloudIDLabel.snp.makeConstraints { make in
            make.top.equalTo(typeControl.snp.bottom).offset(8)
        }
        typeControl.addTarget(self, action: .serverTypeChanged, for: .valueChanged)
    }
    
    func stack(views: [UIView]) {
        if let first = views.get(0), let second = views.get(1) {
            stackTwo(top: first, bottom: second)
            stack(views: views.tail())
        } else {
            return
        }
    }
    
    func stackTwo(top: UIView, bottom: UIView) {
        bottom.snp.makeConstraints { (make) in
            make.top.equalTo(top.snp.bottom).offset(8)
        }
    }
    
    func leadingTrailingToSuper(target: UIView) {
        target.snp.makeConstraints { (make) in
            make.trailing.leading.equalToSuperview()
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
    
    func serverTypeChanged(_ sender: UISegmentedControl) {
        updateVisibility(segment: sender)
    }
    
    func updateVisibility(segment: UISegmentedControl) {
        if let serverType = readServerType(segment) {
            adjustVisibility(serverType)
        } else {
            Log.error("Unable to determine server type.")
        }
    }
    
    func testClicked(_ sender: AnyObject) {
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
