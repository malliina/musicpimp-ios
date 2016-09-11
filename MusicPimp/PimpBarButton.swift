//
//  PimpBarButton.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 14/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpBarButton: UIBarButtonItem {
    let onClick: UIBarButtonItem -> Void
    
    init(title: String, style: UIBarButtonItemStyle, onClick: UIBarButtonItem -> Void) {
        self.onClick = onClick
        super.init()
        self.style = style
        self.title = title
        action = #selector(runOnClick(_:))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func runOnClick(item: UIBarButtonItem) {
        onClick(item)
    }
    
//    static func system(systemStyle: UIBarButtonSystemItem, target: AnyObject?, onClick: UIBarButtonItem -> Void) -> UIBarButtonItem {
//        let a = ActionHack(onClick: onClick)
//        return UIBarButtonItem(barButtonSystemItem: systemStyle, target: target, action: #selector(a.onAction(_:)))
//    }
}

//class ActionHack {
//    let onClick: UIBarButtonItem -> Void
//    
//    init(onClick: UIBarButtonItem -> Void) {
//        self.onClick = onClick
//    }
//    
//    @objc func onAction(item: UIBarButtonItem) {
//        Log.info("Action")
//        return onClick(item)
//    }
//}
