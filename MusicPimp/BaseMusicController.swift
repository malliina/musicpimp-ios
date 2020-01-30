//
//  BaseMusicController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 10/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

class BaseMusicController : PimpTableController, AccessoryDelegate {
    private let log = LoggerFactory.shared.vc(BaseMusicController.self)
    let FolderCellId = "FolderCell"
    let trackReuseIdentifier = "PimpMusicItemCell"
    let defaultCellHeight: CGFloat = 44
    static let accessoryRightPadding: CGFloat = 14
    
    var musicItems: [MusicItem] { [] }
    
    // generic listeners
    var listeners: [RxSwift.Disposable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(SnapMusicCell.self, forCellReuseIdentifier: trackReuseIdentifier)
        registerCell(reuseIdentifier: FolderCellId)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentFeedback == nil ? musicItems.count : 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListening()
    }
    
    func stopListening() {
        for listener in listeners {
            listener.dispose()
        }
        listeners = []
    }
    
    func trackCell(_ item: Track, index: IndexPath) -> SnapMusicCell? {
        if let pimpCell: SnapMusicCell = findCell(trackReuseIdentifier, index: index) {
            pimpCell.title.text = item.title
            pimpCell.accessoryDelegate = self
            return pimpCell
        } else {
            log.error("Unable to find track cell for track \(item.title)")
            return nil
        }
    }
    
    func paintTrackCell(cell: SnapMusicCell, track: Track, isHighlight: Bool, downloadState: TrackProgress?) {
        if let downloadProgress = downloadState {
            if cell.progress.progress < downloadProgress.progress {
//                log.info("From \(cell.progress.progress) to \(downloadProgress.progress)")
                cell.progress.progress = downloadProgress.progress
            }
            if cell.progress.isHidden {
                cell.progress.isHidden = false
            }
        } else {
            cell.progress.isHidden = true
        }
        let (titleColor, selectionStyle) = isHighlight ? (PimpColors.shared.tintColor, UITableViewCell.SelectionStyle.blue) : (PimpColors.shared.titles, UITableViewCell.SelectionStyle.default)
        cell.title.textColor = titleColor
        cell.selectionStyle = selectionStyle
    }
    
    func accessoryTapped(_ sender: UIButton, event: AnyObject) {
        if let row = clickedRow(event) {
            let item = musicItems[row]
            if let track = item as? Track {
                displayActionsForTrack(track, row: row, sender: sender)
            }
            if let folder = item as? Folder {
                displayActionsForFolder(folder, row: row)
            }
        } else {
            log.error("Unable to determine touched row")
        }
    }
    
    // TODO add link to source (SO?)
    func clickedRow(_ touchEvent: AnyObject) -> Int? {
        if let touch = touchEvent.allTouches??.first {
            let point = touch.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: point) {
                return indexPath.row
            }
        }
        return nil
    }
    
    func displayActionsForTrack(_ track: Track, row: Int, sender: UIButton) {
        let title = track.title
        let message = track.artist
        let sheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        sheet.view.window?.backgroundColor = PimpColors.shared.background
        let playAction = playTrackAccessoryAction(track, row: row)
        let addAction = addTrackAccessoryAction(track, row: row)
        let downloadAction = accessoryAction("Download") { _ in
            _ = self.downloadIfNeeded([track])
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        }
        sheet.addAction(playAction)
        sheet.addAction(addAction)
        if !LocalLibrary.sharedInstance.contains(track) {
            sheet.addAction(downloadAction)
        }
        sheet.addAction(cancelAction)
        // For iPad: Positions the action sheet next to the tapped element, in this case the accessory view
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = sender
        }
        self.present(sheet, animated: true, completion: nil)
    }
    
    func playTrackAccessoryAction(_ track: Track, row: Int) -> UIAlertAction {
        return accessoryAction("Play", action: { _ in _ = self.playTrack(track) })
    }
    
    func addTrackAccessoryAction(_ track: Track, row: Int) -> UIAlertAction {
        return accessoryAction("Add", action: { _ in _ = self.addTrack(track) })
    }
    
    func displayActionsForFolder(_ folder: Folder, row: Int) {
        let title = folder.title
        let id = folder.id
        let message = ""
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.actionSheet)
        let playAction = accessoryAction("Play", action: { _ in self.playFolder(id) })
        let addAction = accessoryAction("Add", action: { _ in self.addFolder(id) })
        let downloadAction = accessoryAction("Download") { _ in
            self.withTracks(id: id, f: self.downloadIfNeeded)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { _ in
            
        }
        sheet.addAction(playAction)
        sheet.addAction(addAction)
        if !self.library.isLocal {
            sheet.addAction(downloadAction)
        }
        sheet.addAction(cancelAction)
        self.present(sheet, animated: true, completion: nil)
    }
    
    func accessoryAction(_ title: String, action: @escaping (UIAlertAction) -> Void) -> UIAlertAction {
        return UIAlertAction(title: title, style: UIAlertAction.Style.default, handler: action)
    }


    func playFolder(_ id: FolderID) {
        withTracks(id: id, f: self.playTracksChecked)
    }
    
    func playTrack(_ track: Track) -> ErrorMessage? {
        return playTracksChecked([track]).headOption()
    }
    
    func addFolder(_ id: FolderID) {
        withTracks(id: id, f: self.addTracksChecked)
    }
    
    func withTracks(id: FolderID, f: @escaping ([Track]) -> [ErrorMessage]) {
        library.tracks(id).subscribe { (event) in
            switch event {
            case .success(let ts): let _ = f(ts)
            case .error(let err): self.onError(err)
            }
        }.disposed(by: bag)
    }
    
    func addTrack(_ track: Track) -> ErrorMessage? {
        return addTracksChecked([track]).headOption()
    }
    
    func reload(_ emptyText: String) {
        withReload(emptyText) { }
    }
    
    func withReload(_ emptyText: String, _ code: @escaping () -> Void) {
        onUiThread {
            code()
            self.reloadTable(feedback: self.musicItems.count == 0 ? emptyText : nil)
        }
    }
    
    func withMessage(_ message: String?, _ code: @escaping () -> Void) {
        onUiThread {
            code()
            self.reloadTable(feedback: message)
        }
    }
}
