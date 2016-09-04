//
//  PimpText.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 04/09/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        pimpInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
        pimpInit()
    }
    
    private func pimpInit() {
        super.autocorrectionType = UITextAutocorrectionType.No
        backgroundColor = PimpColors.lighterBackground
        textColor = PimpColors.titles
    }
    
    override func drawPlaceholderInRect(rect: CGRect) {
        if let p: NSString = placeholder, font = self.font {
            let attributes = defaultTextAttributes.addAll([
                NSForegroundColorAttributeName : PimpColors.placeholder,
                NSFontAttributeName: font
            ])
            let boundingRect = p.boundingRectWithSize(rect.size, options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
            let point = CGPoint(x: 0, y: (rect.size.height/2)-boundingRect.size.height/2)
            p.drawAtPoint(point, withAttributes: attributes)
        }
    }
}
