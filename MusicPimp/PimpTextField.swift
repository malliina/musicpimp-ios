//
//  PimpText.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 04/09/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpTextField: UITextField, UITextFieldDelegate {
//    init(text: String?, placeholder: String?) {
//        super.init(frame: CGRect.zero)
//        pimpInit()
//        self.text = text
//        self.placeholderText = placeholder
//    }
    
    var placeholderText: String? {
        get { return placeholder }
        set(newPlaceholder) { attributedPlaceholder = NSAttributedString(string: newPlaceholder ?? "", attributes: [NSForegroundColorAttributeName: PimpColors.placeholder]) }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        pimpInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
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
