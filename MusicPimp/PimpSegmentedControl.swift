//
//  PimpSegmentControl.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 31/07/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpSegmentedControl: UISegmentedControl {
    let log = LoggerFactory.view("PimpSegmentedControl")
    let answer: Int
    var valueChanged: ((PimpSegmentedControl) -> Void)? = nil
    
    init(itemz: [String], valueChanged: @escaping (PimpSegmentedControl) -> Void) {
        log.info("Going along")
        answer = 42
        self.valueChanged = valueChanged
        super.init(items: itemz)
        addTarget(nil, action: #selector(onSegmentChanged(_:)), for: UIControlEvents.valueChanged)
    }
    
    override init(frame: CGRect) {
        answer = 43
        //self.valueChanged = { _ in () }
        super.init(frame: frame)
        log.info("Dummy segment")
    }
    
    required init?(coder aDecoder: NSCoder) {
        answer = 44
        //self.valueChanged = { _ in () }
        super.init(coder: aDecoder)
        log.info("Dummy segment2")
    }
    
    func onSegmentChanged(_ ctrl: PimpSegmentedControl) {
        log.info("Answer: \(answer)")
        if let cb = valueChanged {
            cb(ctrl)
        }
        //valueChanged(ctrl)
    }
    
}
