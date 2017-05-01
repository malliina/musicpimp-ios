//
//  BaseMusicController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 10/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class BaseMusicController : PimpTableController {
    let FolderCellId = "FolderCell"
    let trackReuseIdentifier = "PimpMusicItemCell"
    let defaultCellHeight: CGFloat = 44
    static let accessoryRightPadding: CGFloat = 14
    static let accessoryImageSize = CGSize(width: 16, height: 16)
    static let accessoryImage: UIImage? = UIImage(named: "more_filled_grey-100.png")?.withSize(scaledToSize: accessoryImageSize)
    
    var musicItems: [MusicItem] { return [] }
    
    var listeners: [Disposable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(SnapMusicCell.self, forCellReuseIdentifier: trackReuseIdentifier)
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: FolderCellId)
//        registerNib(trackReuseIdentifier)
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

    
    func cellHeight() -> CGFloat {
        return defaultCellHeight
    }
    
    func trackCell(_ item: Track, index: IndexPath) -> SnapMusicCell? {
        if let pimpCell: SnapMusicCell = findCell(trackReuseIdentifier, index: index) {
            pimpCell.title.text = item.title
            installTrackAccessoryView(pimpCell)
            return pimpCell
        } else {
            Log.error("Unable to find track cell for track \(item.title)")
            return nil
        }
    }
    
    func paintTrackCell(cell: SnapMusicCell, track: Track, isHighlight: Bool, downloadState: TrackProgress?) {
        if let downloadProgress = downloadState {
            cell.progress.progress = downloadProgress.progress
            cell.progress.isHidden = false
        } else {
            cell.progress.isHidden = true
        }
        let (titleColor, selectionStyle) = isHighlight ? (PimpColors.tintColor, UITableViewCellSelectionStyle.blue) : (PimpColors.titles, UITableViewCellSelectionStyle.default)
        cell.title.textColor = titleColor
        cell.selectionStyle = selectionStyle
    }
    
    func installTrackAccessoryView(_ cell: UITableViewCell, _ isLarge: Bool = false) {
        // TODO move the below code to PimpMusicItemCell, then provide observable of accessoryClicked:event
        if let accessory = createTrackAccessory(isLarge: isLarge) {
            cell.accessoryView = accessory
        }
    }
    
    func createTrackAccessory(isLarge: Bool) -> UIButton? {
        if let image = BaseMusicController.accessoryImage {
            let accessoryHeight = cellHeight()
            //let accessoryWidth = accessoryHeight
            let accessoryWidth: CGFloat = defaultCellHeight
            let button = UIButton(type: UIButtonType.custom)
            let frame = CGRect(x: 0, y: 0, width: accessoryWidth, height: accessoryHeight)
            button.frame = frame
            button.setImage(image, for: UIControlState())
            button.backgroundColor = UIColor.clear
            button.contentMode = UIViewContentMode.scaleAspectFit
            // - 15 because otherwise the accessory didn't look good on all cell sizes
            // TODO fix properly once I know how to
            //let maxInset = max(0, accessoryWidth - BaseMusicController.accessoryImageSize.width - 15)
            //let leftInset = min(30, maxInset)
            //button.imageEdgeInsets = UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 15)
            //button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            button.addTarget(self, action: #selector(self.accessoryClicked(_:event:)), for: UIControlEvents.touchUpInside)
            return button
        }
        return nil
    }
    
    func accessoryClicked(_ sender: AnyObject, event: AnyObject) {
        if let row = clickedRow(event) {
            let item = musicItems[row]
            if let track = item as? Track {
                displayActionsForTrack(track, row: row)
            }
            if let folder = item as? Folder {
                displayActionsForFolder(folder, row: row)
            }
        } else {
            Log.error("Unable to determine touched row")
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
    
    func displayActionsForTrack(_ track: Track, row: Int) {
        let title = track.title
        let message = track.artist
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        sheet.view.window?.backgroundColor = PimpColors.background
        let playAction = playTrackAccessoryAction(track, row: row)
        let addAction = addTrackAccessoryAction(track, row: row)
        let downloadAction = accessoryAction("Download") { _ in
            _ = self.downloadIfNeeded([track])
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { _ in
            
        }
        sheet.addAction(playAction)
        sheet.addAction(addAction)
        if !LocalLibrary.sharedInstance.contains(track) {
            sheet.addAction(downloadAction)
        }
        sheet.addAction(cancelAction)
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = self.view
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
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        let playAction = accessoryAction("Play", action: { _ in self.playFolder(id) })
        let addAction = accessoryAction("Add", action: { _ in self.addFolder(id) })
        let downloadAction = accessoryAction("Download") { _ in
            self.withTracks(id: id, f: self.downloadIfNeeded)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { _ in
            
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
        return UIAlertAction(title: title, style: UIAlertActionStyle.default, handler: action)
    }


    func playFolder(_ id: String) {
        withTracks(id: id, f: self.playTracks)
    }
    
    func playTrack(_ track: Track) -> ErrorMessage? {
        return playTracks([track]).headOption()
    }
    
    func addFolder(_ id: String) {
        withTracks(id: id, f: self.addTracks)
    }
    
    func withTracks(id: String, f: @escaping ([Track]) -> [ErrorMessage]) {
        library.tracks(id, onError: onError) { tracks in _ = f(tracks) }
    }
    
    func addTrack(_ track: Track) -> ErrorMessage? {
        return addTracks([track]).headOption()
    }
}
