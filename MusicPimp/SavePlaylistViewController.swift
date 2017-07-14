//
//  SavePlaylistViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

fileprivate extension Selector {
    static let saveClicked = #selector(SavePlaylistViewController.onSave(_:))
    static let cancelClicked = #selector(SavePlaylistViewController.onCancel(_:))
    static let textChanged = #selector(SavePlaylistViewController.textFieldDidChange(_:))
}

protocol SavePlaylistDelegate {
    func onPlaylistSaved(saved: SavedPlaylist)
}

class SavePlaylistViewController: PimpViewController, UITextFieldDelegate {
    let nameLabel = UILabel()
    let nameText = PimpTextField()
    var saveButton: UIBarButtonItem? = nil
    var name: String?
    var tracks: [Track] = []
    var delegate: SavePlaylistDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "NEW PLAYLIST"
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: .saveClicked)
        saveButton = save
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: .cancelClicked)
        self.navigationItem.rightBarButtonItem = save
        if let name = name {
            nameText.text = name
        }
        nameText.delegate = self
        nameText.addTarget(self, action: .textChanged, for: .editingChanged)
        checkValidName()
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nameText.becomeFirstResponder()
    }
    
    func initUI() {
        addSubviews(views: [nameLabel, nameText])
        nameLabel.text = "Playlist Name"
        nameLabel.textColor = PimpColors.titles
        nameLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalTo(nameText.snp.top).offset(-8)
        }
        nameText.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        checkValidName()
    }
    
    func checkValidName() {
        let text = nameText.text ?? ""
        saveButton?.isEnabled = !text.isEmpty
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameText.resignFirstResponder()
        return true
    }
    
    func onCancel(_ sender: UIBarButtonItem) {
        goBack()
    }
    
    func onSave(_ sender: UIBarButtonItem) {
        name = nameText.text ?? ""
        savePlaylist(name: name ?? "")
        goBack()
    }
    
    fileprivate func savePlaylist(name: String) {
        let playlist = SavedPlaylist(id: nil, name: name, tracks: tracks)
        LibraryManager.sharedInstance.active.savePlaylist(playlist, onError: Util.onError) { (id: PlaylistID) -> Void in
            self.delegate?.onPlaylistSaved(saved: SavedPlaylist(id: id, name: playlist.name, tracks: playlist.tracks))
            Log.info("Saved playlist with name \(playlist.name) and ID \(id.id)")
        }
    }
    
    func goBack() {
        dismiss(animated: true, completion: nil)
    }
}
