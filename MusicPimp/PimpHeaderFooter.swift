//
//  PimpHeaderFooter.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpHeaderFooter {
    static func withText(_ text: String) -> UITableViewHeaderFooterView {
        let view = UITableViewHeaderFooterView()
        view.contentView.backgroundColor = PimpColors.background
        view.textLabel?.text = text
        return view
    }
}
