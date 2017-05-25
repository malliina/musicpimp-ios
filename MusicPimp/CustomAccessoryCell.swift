//
//  CustomAccessoryCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/07/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

protocol AccessoryDelegate {
    func accessoryTapped(_ sender: AnyObject, event: AnyObject)
}

class CustomAccessoryCell: PimpCell {
    static let defaultCellHeight: CGFloat = 44
    
    static let accessoryImageSize = CGSize(width: 16, height: 16)
    static let accessoryImage: UIImage? = UIImage(named: "more_filled_grey-100.png")?
        .withSize(scaledToSize: accessoryImageSize)
    var accessoryDelegate: AccessoryDelegate? = nil
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Removes right-side accessory view margin
        // http://stackoverflow.com/questions/20534075/get-rid-of-padding-for-uitableviewcell-custom-accessoryview
        if let accessoryView = self.accessoryView {
            accessoryView.frame.origin.x = self.bounds.width - accessoryView.frame.width
        }
    }
    
    func installTrackAccessoryView(height: CGFloat = CustomAccessoryCell.defaultCellHeight) {
        if let accessory = createTrackAccessory(height: height) {
            self.accessoryView = accessory
        }
    }
    
    private func createTrackAccessory(height: CGFloat) -> UIButton? {
        if let image = CustomAccessoryCell.accessoryImage {
            //let accessoryHeight = cellHeight()
            //let accessoryWidth = accessoryHeight
            let accessoryWidth: CGFloat = CustomAccessoryCell.defaultCellHeight
            let button = UIButton(type: UIButtonType.custom)
            let frame = CGRect(x: 0, y: 0, width: accessoryWidth, height: height)
            button.frame = frame
            button.setImage(image, for: UIControlState())
            button.backgroundColor = UIColor.clear
            button.contentMode = UIViewContentMode.scaleAspectFit
            button.addTarget(self, action: #selector(self.accessoryClicked(_:event:)), for: UIControlEvents.touchUpInside)
            return button
        }
        return nil
    }
    
    func accessoryClicked(_ sender: AnyObject, event: AnyObject) {
        accessoryDelegate?.accessoryTapped(sender, event: event)
    }

}
