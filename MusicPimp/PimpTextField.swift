//
//  PimpText.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 04/09/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpTextField: UITextField, UITextFieldDelegate {
    var placeholderText: String? {
        get { return placeholder }
        set(newPlaceholder) { attributedPlaceholder = NSAttributedString(string: newPlaceholder ?? "", attributes: [NSAttributedStringKey.foregroundColor: PimpColors.placeholder]) }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        pimpInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pimpInit()
    }
    
    fileprivate func pimpInit() {
        delegate = self
        autocorrectionType = .no
        backgroundColor = PimpColors.lighterBackground
        textColor = PimpColors.titles
        borderStyle = .roundedRect
        autocapitalizationType = .none
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
