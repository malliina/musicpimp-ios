
import Foundation

/// Used at least to list alarms, playlists
class MainSubCell: SnapCell {
    // empirical - no clue how. elements + margins equal 62 pixels
    static let height: CGFloat = 70
    let main = PimpLabel.create()
    let sub = PimpLabel.create(textColor: PimpColors.shared.subtitles, fontSize: 15)
    
    override func configureView() {
        installTrackAccessoryView(height: MainSubCell.height)
        contentView.addSubview(main)
        main.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(8)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView)
        }
        
        contentView.addSubview(sub)
        sub.snp.makeConstraints { make in
            make.top.equalTo(main.snp.bottom).offset(6)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView).inset(8)
        }
    }
}
