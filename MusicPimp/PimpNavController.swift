//
//  PimpNavController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/09/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpNavController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationBar.backgroundColor = PimpColors.background
//        self.navigationBar.barTintColor = PimpColors.background
        
        self.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor()
        ]
    }
}
