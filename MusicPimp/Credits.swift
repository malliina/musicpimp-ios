import Foundation
import SnapKit

// https://medium.com/@kenzai/how-to-write-clean-beautiful-storyboard-free-views-in-swift-with-snapkit-443e74fc23b2
class Credits: PimpViewController {
  let developedLabel = PimpLabel.centered(text: "Developed by Michael Skogberg.")
  let designedLabel = PimpLabel.centered(text: "Design by Alisa.")

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "CREDITS"
    initUI()
  }

  func initUI() {
    addSubviews(views: [developedLabel, designedLabel])

    developedLabel.snp.makeConstraints { make in
      make.leadingMargin.trailingMargin.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-70)
    }

    designedLabel.snp.makeConstraints { make in
      make.top.greaterThanOrEqualTo(developedLabel.snp.bottom)
      make.leadingMargin.trailingMargin.centerX.equalToSuperview()
    }

    if let bundleMeta = Bundle.main.infoDictionary,
      let appVersion = bundleMeta["CFBundleShortVersionString"] as? String,
      let buildId = bundleMeta["CFBundleVersion"] as? String
    {
      let versionLabel = PimpLabel.centered(text: "Version \(appVersion) build \(buildId)")
      view.addSubview(versionLabel)
      versionLabel.textColor = PimpColors.shared.subtitles
      versionLabel.font = UIFont.systemFont(ofSize: 14)
      versionLabel.snp.makeConstraints { (make) in
        make.top.greaterThanOrEqualTo(designedLabel.snp.bottom).offset(24)
        make.leadingMargin.trailingMargin.centerX.equalToSuperview()
        make.bottom.equalToSuperview().inset(20)
      }
    } else {
      designedLabel.snp.updateConstraints { (make) in
        make.bottom.equalToSuperview().inset(20)
      }
    }
  }
}
