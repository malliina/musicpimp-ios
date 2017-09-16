//
//  EditEndpointController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

fileprivate extension Selector {
    static let saveClicked = #selector(EditEndpointController.onSave(_:))
    static let cancelClicked = #selector(EditEndpointController.onCancel(_:))
    static let serverTypeChanged = #selector(EditEndpointController.serverTypeChanged(_:))
    static let testClicked = #selector(EditEndpointController.testClicked(_:))
}

protocol EditEndpointDelegate {
    func endpointUpdated(_ endpoint: Endpoint)
}

class EditEndpointController: PimpViewController {
    let log = LoggerFactory.vc("EditEndpointController")
    let scrollView = UIScrollView()
    let content = UIView()
    let nameLabel = UILabel()
    let typeControl = UISegmentedControl(items: ["Cloud", "MusicPimp"])
    let nameField = PimpTextField()
    let portField = PimpTextField()
    let usernameLabel = UILabel()
    let usernameField = PimpTextField()
    let passwordLabel = UILabel()
    let passwordField = PimpTextField()
    let protocolControl = UISegmentedControl(items: ["HTTP", "HTTPS"])
    let portLabel = UILabel()
    let addressLabel = UILabel()
    let addressField = PimpTextField()
    let cloudIDLabel = UILabel()
    let cloudIDField = PimpTextField()
    let activateLabel = UILabel()
    let activateSwitch = UISwitch()
    let testButton = UIButton()
    let feedbackText = UITextView()
    
    var editedItem: Endpoint? = nil
    var delegate: EditEndpointDelegate? = nil
    
    var pimpConstraint: Constraint? = nil
    var cloudConstraint: Constraint? = nil
    
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
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: .cancelClicked)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: .saveClicked)
        view.addSubview(scrollView)
        scrollView.addSubview(content)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(view).inset(UIEdgeInsets.zero)
        }
        content.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(scrollView).inset(UIEdgeInsets.zero)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().priority(.medium)
            make.width.lessThanOrEqualTo(500).priority(.high)
        }
        let labels = [nameLabel, portLabel, addressLabel, usernameLabel, passwordLabel, cloudIDLabel, activateLabel]
        labels.forEach { (label) in
            label.textColor = PimpColors.titles
        }
        let views: [UIView] = [typeControl, cloudIDLabel, cloudIDField, nameLabel, nameField, addressLabel, addressField, portLabel, portField, usernameLabel, usernameField, passwordLabel, passwordField, protocolControl, activateLabel, activateSwitch, testButton, feedbackText]
        views.forEach { (v) in
            content.addSubview(v)
        }
        typeControl.snp.makeConstraints { make in
            make.top.equalTo(content).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        typeControl.selectedSegmentIndex = 0
        cloudIDLabel.text = "Cloud ID"
        cloudIDLabel.snp.makeConstraints { (make) in
            make.top.equalTo(typeControl.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        nameLabel.text = "Name"
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(typeControl.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        cloudIDField.placeholderText = "cloud123"
        cloudIDField.snp.makeConstraints { (make) in
            make.top.equalTo(cloudIDLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        nameField.placeholderText = "home computer"
        nameField.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        addressLabel.text = "Address"
        addressLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameField.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        addressField.placeholderText = "host or IP"
        addressField.keyboardType = .URL
        addressField.snp.makeConstraints { (make) in
            make.top.equalTo(addressLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        portLabel.text = "Port"
        portLabel.snp.makeConstraints { (make) in
            make.top.equalTo(addressField.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        portField.placeholderText = "8456"
        portField.keyboardType = .numberPad
        portField.snp.makeConstraints { (make) in
            make.top.equalTo(portLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        usernameLabel.text = "Username"
        usernameLabel.snp.makeConstraints { (make) in
            // pimp
            self.pimpConstraint = make.top.equalTo(portField.snp.bottom).offset(8).constraint
            // cloud
            self.cloudConstraint = make.top.equalTo(cloudIDField.snp.bottom).offset(8).constraint
            make.leading.trailing.equalTo(content).inset(8)
        }
        usernameField.placeholderText = "admin"
        usernameField.snp.makeConstraints { (make) in
            make.top.equalTo(usernameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        passwordLabel.text = "Password"
        passwordLabel.snp.makeConstraints { (make) in
            make.top.equalTo(usernameField.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        passwordField.isSecureTextEntry = true
        passwordField.keyboardAppearance = .dark
        passwordField.snp.makeConstraints { (make) in
            make.top.equalTo(passwordLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        protocolControl.selectedSegmentIndex = 0
        protocolControl.snp.makeConstraints { (make) in
            make.top.equalTo(passwordField.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        activateLabel.text = "Set as active music source"
        activateLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(content).inset(8)
            make.centerY.equalTo(activateSwitch)
        }
        activateSwitch.snp.makeConstraints { (make) in
            make.top.equalTo(protocolControl.snp.bottom).offset(8)
            make.trailing.equalTo(content).inset(8)
            make.leading.equalTo(activateLabel.snp.trailing).offset(8)
        }
        testButton.setTitle("Test Connectivity", for: .normal)
        testButton.setTitleColor(PimpColors.tintColor, for: UIControlState.normal)
        testButton.snp.makeConstraints { (make) in
            make.top.equalTo(activateSwitch.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
        }
        feedbackText.backgroundColor = PimpColors.background
        feedbackText.snp.makeConstraints { (make) in
            make.top.equalTo(testButton.snp.bottom).offset(8)
            make.leading.trailing.equalTo(content).inset(8)
            make.height.equalTo(60)
            make.bottom.equalTo(content).inset(8)
        }
        // Removes space between text view border and text
        feedbackText.textContainerInset = .zero
        feedbackText.textContainer.lineFragmentPadding = 0
        feedbackText.isEditable = false
        typeControl.addTarget(self, action: .serverTypeChanged, for: .valueChanged)
        testButton.addTarget(self, action: .testClicked, for: .touchUpInside)
    }
    
    func onSave(_ item: UIBarButtonItem) {
        saveChanges()
        goBack()
    }
    
    func saveChanges() {
        if let endpoint = parseEndpoint() {
            PimpSettings.sharedInstance.save(endpoint)
            if activateSwitch.isOn {
                log.info("Activating \(endpoint.name)")
                let _ = LibraryManager.sharedInstance.use(endpoint: endpoint)
            }
            delegate?.endpointUpdated(endpoint)
        }
    }
    
    func onCancel(_ item: UIBarButtonItem) {
        goBack()
    }
    
    func goBack() {
        let isAddMode = presentingViewController != nil
        if isAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func serverTypeChanged(_ sender: UISegmentedControl) {
        updateVisibility(segment: sender)
    }
    
    func updateVisibility(segment: UISegmentedControl) {
        if let serverType = readServerType(segment) {
            adjustVisibility(serverType)
        } else {
            log.error("Unable to determine server type.")
        }
    }
    
    func testClicked(_ sender: AnyObject) {
        if let endpoint = parseEndpoint() {
            log.info("Testing \(endpoint.httpBaseUrl)")
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
        if cloudVisible {
            pimpConstraint?.deactivate()
            cloudConstraint?.activate()
        } else {
            pimpConstraint?.activate()
            cloudConstraint?.deactivate()
        }
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
        log.info("Test failed: \(msg)")
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
}
