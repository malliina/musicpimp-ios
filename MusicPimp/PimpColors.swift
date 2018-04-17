//
//  PimpColors.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 27/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpColors {
    static let white = Colors.rgb(244, green: 244, blue: 244)
    static let text = white
    static let background = Colors.rgb(2, green: 23, blue: 42)
    static let header = Colors.rgb(23, green: 46, blue: 84)
    static let lighterBackground = Colors.rgb(3, green: 32, blue: 52)
    static let titles = white
    static let separator = Colors.rgb(255, green: 255, blue: 255, alpha: 0.2)
    static let notSelected = Colors.rgb(161, green: 161, blue: 161)
    static let subtitles = PimpColors.notSelected
    static let selected = Colors.rgb(36, green: 131, blue: 233)
    static let selectedBackground = PimpColors.selected
//    static let tintColor = UIColor.greenColor()
    static let tintColor = PimpColors.selected
    // used by tabbar, navigationbar
    static let barStyle = UIBarStyle.black
    static let deletion = UIColor.red
    static let deletionHighlighted = Colors.rgb(139, green: 0, blue: 0)
    static let placeholder = PimpColors.separator
    static let titleFont = UIFont.boldSystemFont(ofSize: 13)
}
