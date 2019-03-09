//
//  PimpBarButton.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 14/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpBarButton: UIBarButtonItem {
    let onClick: (UIBarButtonItem) -> Void
    
    init(title: String, style: UIBarButtonItemStyle, onClick: @escaping (UIBarButtonItem) -> Void) {
        self.onClick = onClick
        super.init()
        self.style = style
        self.title = title
        action = #selector(runOnClick(_:))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func runOnClick(_ item: UIBarButtonItem) {
        onClick(item)
    }
}
