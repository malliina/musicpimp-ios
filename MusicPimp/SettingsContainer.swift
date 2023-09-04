
import Foundation

class SettingsContainer: ContainerParent {
    let child = SettingsController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "SETTINGS"
        initUI()
    }
    
    func initUI() {
        initChild(child)
        child.view.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalTo(view)
            make.bottom.equalTo(playbackFooter.snp.top)
        }
    }
}
