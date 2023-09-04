
import Foundation

// https://medium.com/swift-digest/good-swift-bad-swift-part-1-f58f71da3575
class BaseView: UIView {
    init() {
        super.init(frame: CGRect.zero)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
    func addSubviews(views: [UIView]) {
        views.forEach(addSubview)
    }
    
    func configureView() {
        
    }
}
