//
//  MainAndSubtitleCell
//  MusicPimp
//
//  Created by Michael Skogberg on 17/07/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import UIKit

class MainAndSubtitleCell: CustomAccessoryCell {

    @IBOutlet var mainTitle: UILabel!
    @IBOutlet var subtitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = PimpColors.background
        mainTitle.textColor = PimpColors.titles
        subtitle.textColor = PimpColors.titles
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
