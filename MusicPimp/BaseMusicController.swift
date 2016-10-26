//
//  BaseMusicController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 10/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class BaseMusicController : PimpTableController {
    let trackReuseIdentifier = "PimpMusicItemCell"
    let defaultCellHeight: CGFloat = 44
    static let accessoryRightPadding: CGFloat = 14
    
    var musicItems: [MusicItem] { return [] }
    
    var listeners: [Disposable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNib(trackReuseIdentifier)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicItems.count
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
    
    func trackCell(_ item: Track, index: IndexPath) -> PimpMusicItemCell? {
        if let pimpCell: PimpMusicItemCell = findCell(trackReuseIdentifier, index: index) {
            pimpCell.titleLabel?.text = item.title
            installTrackAccessoryView(pimpCell)
            return pimpCell
        } else {
            Log.error("Unable to find track cell for track \(item.title)")
            return nil
        }
    }
    
    func paintTrackCell(cell: PimpMusicItemCell, track: Track, isHighlight: Bool, downloadState: [Track: TrackProgress]) {
        if let downloadProgress = downloadState[track] {
            //info("Setting progress to \(downloadProgress.progress)")
            cell.progressView.progress = downloadProgress.progress
            cell.progressView.isHidden = false
        } else {
            cell.progressView.isHidden = true
        }
        let isHighlight = self.player.current().track?.id == track.id
        let (titleColor, selectionStyle) = isHighlight ? (PimpColors.tintColor, UITableViewCellSelectionStyle.blue) : (PimpColors.titles, UITableViewCellSelectionStyle.default)
        cell.titleLabel?.textColor = titleColor
        cell.selectionStyle = selectionStyle
    }
    
    func installTrackAccessoryView(_ cell: UITableViewCell) {
        // TODO move the below code to PimpMusicItemCell, then provide observable of accessoryClicked:event
        if let accessory = createTrackAccessory() {
            cell.accessoryView = accessory
        }
    }
    
    func createTrackAccessory() -> UIButton? {
        let topAndBottomInset: CGFloat = max(0, (cellHeight() - defaultCellHeight) / 2 + 10)
        let leftInset: CGFloat = 18
        if let image = UIImage(named: "more_filled_grey-100.png") {
            let rightPadding = BaseMusicController.accessoryRightPadding
            let button = UIButton(type: UIButtonType.custom)
            let frame = CGRect(x: 0, y: 0, width: defaultCellHeight + rightPadding, height: cellHeight())
            button.frame = frame
            button.setImage(image, for: UIControlState())
            button.backgroundColor = UIColor.clear
            button.contentEdgeInsets = UIEdgeInsets(top: topAndBottomInset, left: leftInset, bottom: topAndBottomInset, right: rightPadding)
            button.contentMode = UIViewContentMode.scaleAspectFit
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
                return (indexPath as NSIndexPath).row
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
            self.downloadIfNeeded([track])
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
//            popover.sourceRect = self.view.frame
        }
        //sheet.view.tintColor = UIColor.greenColor()
        //let sheetView = sheet.view.subviews.headOption()?.subviews.headOption()
        //sheetView?.backgroundColor = UIColor.greenColor()
        //sheetView?.layer.cornerRadius = 15
        self.present(sheet, animated: true, completion: nil)
    }
    
    func playTrackAccessoryAction(_ track: Track, row: Int) -> UIAlertAction {
        return accessoryAction("Play", action: { _ in self.playTrack(track) })
    }
    
    func addTrackAccessoryAction(_ track: Track, row: Int) -> UIAlertAction {
        return accessoryAction("Add", action: { _ in self.addTrack(track) })
    }
    
    func displayActionsForFolder(_ folder: Folder, row: Int) {
        let title = folder.title
        let id = folder.id
        let message = ""
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        let playAction = accessoryAction("Play", action: { _ in self.playFolder(id) })
        let addAction = accessoryAction("Add", action: { _ in self.addFolder(id) })
        let downloadAction = accessoryAction("Download") { _ in
            self.library.tracks(id, onError: self.onError, f: self.downloadIfNeeded)
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
        library.tracks(id, onError: onError, f: playTracks)
    }
    
    func playTrack(_ track: Track) {
        playTracks([track])
    }
    
    func addFolder(_ id: String) {
        info("Adding folder")
        library.tracks(id, onError: onError, f: addTracks)
    }
    
    func addTrack(_ track: Track) {
        addTracks([track])
    }
}
