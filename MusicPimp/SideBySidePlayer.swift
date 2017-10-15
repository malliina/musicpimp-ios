//
//  SideBySidePlayer.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SideBySidePlayer: ContainerParent {
    let playerVc = PlayerController()
    let queueVc = PlayQueueController()
    
    override var currentFooterHeight: CGFloat { get { return 66 } }
    override var preferredPlaybackFooterHeight: CGFloat { get { return 66 } }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initChild(playerVc)
        initChild(queueVc)
        snapStacked()
        updateNavbar()
    }
    
    func updateNavbar() {
        navigationItem.title = "PLAYER"
        navigationItem.leftBarButtonItems = queueVc.navigationItem.leftBarButtonItems
        navigationItem.rightBarButtonItems = (queueVc.navigationItem.rightBarButtonItems ?? []) + (playerVc.navigationItem.rightBarButtonItems ?? [])
    }
    
    func snapStacked() {
        // stacked
        playerVc.view.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.trailing.leading.equalTo(view)
            make.height.equalTo(queueVc.view).offset(100)
        }
        queueVc.view.snp.makeConstraints { (make) in
            make.top.equalTo(playerVc.view.snp.bottom).offset(16)
            make.bottom.equalTo(playbackFooter.snp.top)
            make.leading.trailing.equalTo(playerVc.view)
        }
        playbackFooter.setBigSize()
    }
}
