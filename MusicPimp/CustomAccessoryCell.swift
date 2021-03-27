//
//  CustomAccessoryCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/07/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

protocol AccessoryDelegate {
    func accessoryTapped(_ sender: UIButton, event: AnyObject)
}

class CustomAccessoryCell: PimpCell {
    let log = LoggerFactory.shared.view(CustomAccessoryCell.self)
    static let defaultCellHeight: CGFloat = 44
    let accessoryWidth: CGFloat = 44
    
    static let accessoryImageSize = CGSize(width: 16, height: 16)
    static let disclosureIndicatorSize = CGSize(width: 10, height: 14)
    static let trackAccessory = UIImage(named: "more_filled_grey-100.png")!.withSize(scaledToSize: accessoryImageSize)
    static let folderAccessory = UIImage(named: "chevron-right-100.png")!.withSize(scaledToSize: disclosureIndicatorSize)
    var accessoryDelegate: AccessoryDelegate? = nil
    
    // call from layoutSubviews if necessary
    func removeAccessoryMargin() {
        // Removes right-side accessory view margin
        // Try to find another solution; this does not respect UITableView.cellLayoutMarginsFollowReadableWidth
        // http://stackoverflow.com/questions/20534075/get-rid-of-padding-for-uitableviewcell-custom-accessoryview
        if let accessoryView = self.accessoryView {
            accessoryView.frame.origin.x = frame.width - accessoryView.frame.width
        }
    }
    
    func installTrackAccessoryView(height: CGFloat = CustomAccessoryCell.defaultCellHeight) {
        self.accessoryView = createAccessory(height: height, image: CustomAccessoryCell.trackAccessory)
    }
    
    func installDisclosureAccessoryView(height: CGFloat = CustomAccessoryCell.defaultCellHeight) {
        self.accessoryView = createAccessory(height: height, image: CustomAccessoryCell.folderAccessory)
    }
    
    private func createAccessory(height: CGFloat, image: UIImage) -> UIButton {
        let button = UIButton(type: .custom)
        let frame = CGRect(x: 0, y: 0, width: accessoryWidth, height: height)
        button.frame = frame
        button.setImage(image, for: UIControl.State())
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(self.accessoryClicked(_:event:)), for: .touchUpInside)
        button.contentEdgeInsets = .zero
        return button
    }
    
    @objc func accessoryClicked(_ sender: UIButton, event: AnyObject) {
        if let accessoryDelegate = accessoryDelegate {
            accessoryDelegate.accessoryTapped(sender, event: event)
        } else {
            log.error("No accessory delegate")
        }
    }
}
