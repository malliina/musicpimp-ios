
import Foundation

class SnapTrackCell: SnapCell {
    let progress = UIProgressView(progressViewStyle: .default)

    override func configureView() {
        super.configureView()
        installTrackAccessoryView()
        initProgress()
    }

    func initProgress() {
        contentView.addSubview(progress)
        progress.snp.makeConstraints { make in
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.top.equalTo(title.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
        }
    }
}
