
import Foundation

class PimpMusicItemCell : CustomAccessoryCell {
    
    @IBOutlet var progressView: UIProgressView!
    
    @IBOutlet var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.textColor = PimpColors.titles
//        backgroundColor = PimpColors.background
//        titleLabel.textColor = PimpColors.titles
    }
}
