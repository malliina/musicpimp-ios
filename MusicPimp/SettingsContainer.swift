//
//  SettingsContainer.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/10/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SettingsContainer: ContainerParent {
    let child = SettingsController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "SETTINGS"
        initUI()
    }
    
    func initUI() {
        initChild(child)
        child.view.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalTo(view)
            make.bottom.equalTo(playbackFooter.snp.top)
        }
    }
}
