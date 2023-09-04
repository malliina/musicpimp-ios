
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
    let log = LoggerFactory.shared.vc(SavePlaylistViewController.self)
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
        nameLabel.textColor = PimpColors.shared.titles
        nameLabel.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.bottom.equalTo(nameText.snp.top).offset(-8)
        }
        nameText.snp.makeConstraints { (make) in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
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
    
    @objc func onCancel(_ sender: UIBarButtonItem) {
        goBack()
    }
    
    @objc func onSave(_ sender: UIBarButtonItem) {
        name = nameText.text ?? ""
        savePlaylist(name: name ?? "")
        goBack()
    }
    
    fileprivate func savePlaylist(name: String) {
        // TODO check Duration.zero and length, why are these necessary?
        let playlist = SavedPlaylist(id: nil, name: name, trackCount: tracks.count, duration: Duration.Zero, tracks: tracks)
        run(LibraryManager.sharedInstance.active.savePlaylist(playlist)) { id in
            self.delegate?.onPlaylistSaved(saved: SavedPlaylist(id: id, name: playlist.name, trackCount: playlist.tracks.count, duration: playlist.duration, tracks: playlist.tracks))
            self.log.info("Saved playlist with name \(playlist.name) and ID \(id.id)")
        }
    }
}
