//
//  BaseMusicController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 10/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class BaseMusicController : PimpTableController {
    let customAccessorySize = 44
    let maxNewDownloads = 2000
    
    var feedback: UILabel? = nil
    
    var musicItems: [MusicItem] { return [] }
    // used for informational and error messages for the user
    var feedbackMessage: String? = nil
    
    static let feedbackIdentifier = "FeedbackCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: BaseMusicController.feedbackIdentifier)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(musicItems.count, 1)
    }
    
    func trackCell(item: Track) -> PimpMusicItemCell? {
        let arr = NSBundle.mainBundle().loadNibNamed("PimpMusicItemCell", owner: self, options: nil)
        if let pimpCell = arr[0] as? PimpMusicItemCell {
            pimpCell.titleLabel?.text = item.title
            if let image = UIImage(named: "more_filled_grey-100.png") {
                let button = UIButton(type: UIButtonType.Custom)
                button.frame = CGRect(x: 0, y: 0, width: customAccessorySize, height: customAccessorySize)
                button.setBackgroundImage(image, forState: UIControlState.Normal)
                button.backgroundColor = UIColor.clearColor()
                button.addTarget(self, action: "accessoryClicked:event:", forControlEvents: UIControlEvents.TouchUpInside)
                pimpCell.accessoryView = button
                return pimpCell
            }
        }
        return nil
    }
    
    func accessoryClicked(sender: AnyObject, event: AnyObject) {
        if let touch = event.allTouches()?.first {
            let point = touch.locationInView(tableView)
            if let indexPath = tableView.indexPathForRowAtPoint(point) {
                let item = musicItems[indexPath.row]
                if let track = item as? Track {
                    displayActionsForTrack(track)
                }
                if let folder = item as? Folder {
                    displayActionsForFolder(folder)
                }
                
                Log.info("Clicked \(item.title)")
            }
        }
    }
    
    func displayActionsForTrack(track: Track) {
        let title = track.title
        let message = track.artist
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let playAction = UIAlertAction(title: "Play", style: UIAlertActionStyle.Default) { (a) -> Void in
            self.playTrack(track)
        }
        let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.Default) { (a) -> Void in
            self.addTrack(track)
        }
        let downloadAction = UIAlertAction(title: "Download", style: UIAlertActionStyle.Default) { (a) -> Void in
            self.downloadIfNeeded([track])
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (a) -> Void in
            
        }
        sheet.addAction(playAction)
        sheet.addAction(addAction)
        if !LocalLibrary.sharedInstance.contains(track) {
            sheet.addAction(downloadAction)
        }
        sheet.addAction(cancelAction)
        self.presentViewController(sheet, animated: true, completion: nil)
    }
    
    func displayActionsForFolder(folder: Folder) {
        let title = folder.title
        let id = folder.id
        let message = ""
        let sheet = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let playAction = UIAlertAction(title: "Play", style: UIAlertActionStyle.Default) { (a) -> Void in
            self.playFolder(id)
        }
        let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.Default) { (a) -> Void in
            self.addFolder(id)
        }
        let downloadAction = UIAlertAction(title: "Download", style: UIAlertActionStyle.Default) { (a) -> Void in
            self.library.tracks(id, onError: self.onError, f: self.downloadIfNeeded)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (a) -> Void in
            
        }
        sheet.addAction(playAction)
        sheet.addAction(addAction)
        if !self.library.isLocal {
            sheet.addAction(downloadAction)
        }
        sheet.addAction(cancelAction)
        self.presentViewController(sheet, animated: true, completion: nil)
    }
    
    func onError(error: PimpError) {
        let message = PimpErrorUtil.stringify(error)
        info(message)
    }

    func playFolder(id: String) {
        library.tracks(id, onError: onError, f: playTracks)
    }
    
    func playTrack(track: Track) {
        playTracks([track])
    }
    
    func playTracks(tracks: [Track]) {
        if let first = tracks.first {
            playAndDownload(first)
            addTracks(tracks.tail())
        }
    }
    
    func addFolder(id: String) {
        info("Adding folder")
        library.tracks(id, onError: onError, f: addTracks)
    }
    
    func addTrack(track: Track) {
        addTracks([track])
    }
    
    func addTracks(tracks: [Track]) {
        if !tracks.isEmpty {
            info("Adding \(tracks.count) tracks")
            player.playlist.add(tracks)
            downloadIfNeeded(tracks)
        }
    }
    
    func playAndDownload(track: Track) {
        player.resetAndPlay(track)
        downloadIfNeeded([track])
    }
    
    func downloadIfNeeded(tracks: [Track]) {
        if !library.isLocal && player.isLocal && settings.cacheEnabled {
            let newTracks = tracks.filter({ !LocalLibrary.sharedInstance.contains($0) })
            let tracksToDownload = newTracks.take(maxNewDownloads)
            for track in tracksToDownload {
                startDownload(track)
            }
        }
    }
    
    func startDownload(track: Track) {
        BackgroundDownloader.musicDownloader.download(track.url, relativePath: track.path)
    }
}
