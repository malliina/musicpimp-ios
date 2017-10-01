//
//  PlaybackContainer.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/10/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class PlaybackContainer: ContainerParent {
    let navTitle: String
    let child: UIViewController
    
    required init(title: String, child: UIViewController) {
        self.navTitle = title
        self.child = child
        super.init(footerHeight: ContainerParent.defaultFooterHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = navTitle
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
