//
//  PimpViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/09/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = PimpColors.background
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: PimpColors.titleFont
        ]
    }
}
