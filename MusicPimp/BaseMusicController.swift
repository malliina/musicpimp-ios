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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNib(trackReuseIdentifier)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicItems.count
    }
    
    func cellHeight() -> CGFloat {
        return defaultCellHeight
    }
    
    func trackCell(item: Track, index: NSIndexPath) -> PimpMusicItemCell? {
        if let pimpCell: PimpMusicItemCell = findCell(trackReuseIdentifier, index: index) {
            pimpCell.titleLabel?.text = item.title
            installTrackAccessoryView(pimpCell)
            return pimpCell
        } else {
            Log.error("Unable to find track cell for track \(item.title)")
            return nil
        }
    }
    
    func installTrackAccessoryView(cell: UITableViewCell) {
        // TODO move the below code to PimpMusicItemCell, then provide observable of accessoryClicked:event
        if let accessory = createTrackAccessory() {
            cell.accessoryView = accessory
        }
    }
    
    func createTrackAccessory() -> UIButton? {
        let topAndBottomInset: CGFloat = max(0, (cellHeight() - defaultCellHeight) / 2)
        if let image = UIImage(named: "more_filled_grey-100.png") {
            let rightPadding = BaseMusicController.accessoryRightPadding
            let button = UIButton(type: UIButtonType.Custom)
            let frame = CGRect(x: 0, y: 0, width: defaultCellHeight + rightPadding, height: cellHeight())
            button.frame = frame
            button.setImage(image, forState: UIControlState.Normal)
            button.backgroundColor = UIColor.clearColor()
            button.contentEdgeInsets = UIEdgeInsets(top: topAndBottomInset, left: 0, bottom: topAndBottomInset, right: rightPadding)
            button.contentMode = UIViewContentMode.ScaleAspectFit
            button.addTarget(self, action: #selector(self.accessoryClicked(_:event:)), forControlEvents: UIControlEvents.TouchUpInside)
            return button
        }
        return nil
    }
    
    func accessoryClicked(sender: AnyObject, event: AnyObject) {
        if let row = clickedRow(event) {
            let item = musicItems[row]
            if let track = item as? Track {
                displayActionsForTrack(track, row: row)
            }
            if let folder = item as? Folder {
                displayActionsForFolder(folder, row: row)
            }
            Log.info("Clicked \(item.title)")
        } else {
            Log.error("Unable to determine touched row")
        }
    }
    
    // TODO add link to source (SO?)
    func clickedRow(touchEvent: AnyObject) -> Int? {
        if let touch = touchEvent.allTouches()?.first {
            let point = touch.locationInView(tableView)
            if let indexPath = tableView.indexPathForRowAtPoint(point) {
                return indexPath.row
            }
        }
        return nil
    }
    
    func displayActionsForTrack(track: Track, row: Int) {
        let title = track.title
        let message = track.artist
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let playAction = playTrackAccessoryAction(track, row: row)
        let addAction = addTrackAccessoryAction(track, row: row)
        let downloadAction = accessoryAction("Download") { _ in
            self.downloadIfNeeded([track])
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { _ in
            
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
        self.presentViewController(sheet, animated: true, completion: nil)
    }
    
    func playTrackAccessoryAction(track: Track, row: Int) -> UIAlertAction {
        return accessoryAction("Play", action: { _ in self.playTrack(track) })
    }
    
    func addTrackAccessoryAction(track: Track, row: Int) -> UIAlertAction {
        return accessoryAction("Add", action: { _ in self.addTrack(track) })
    }
    
    func displayActionsForFolder(folder: Folder, row: Int) {
        let title = folder.title
        let id = folder.id
        let message = ""
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let playAction = accessoryAction("Play", action: { _ in self.playFolder(id) })
        let addAction = accessoryAction("Add", action: { _ in self.addFolder(id) })
        let downloadAction = accessoryAction("Download") { _ in
            self.library.tracks(id, onError: self.onError, f: self.downloadIfNeeded)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { _ in
            
        }
        sheet.addAction(playAction)
        sheet.addAction(addAction)
        if !self.library.isLocal {
            sheet.addAction(downloadAction)
        }
        sheet.addAction(cancelAction)
        self.presentViewController(sheet, animated: true, completion: nil)
    }
    
    func accessoryAction(title: String, action: UIAlertAction -> Void) -> UIAlertAction {
        return UIAlertAction(title: title, style: UIAlertActionStyle.Default, handler: action)
    }


    func playFolder(id: String) {
        library.tracks(id, onError: onError, f: playTracks)
    }
    
    func playTrack(track: Track) {
        playTracks([track])
    }
    
    func addFolder(id: String) {
        info("Adding folder")
        library.tracks(id, onError: onError, f: addTracks)
    }
    
    func addTrack(track: Track) {
        addTracks([track])
    }
}
