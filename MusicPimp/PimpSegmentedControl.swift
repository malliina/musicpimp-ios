
import Foundation

class PimpSegmentedControl: UISegmentedControl {
    let log = LoggerFactory.shared.view(PimpSegmentedControl.self)
    let answer: Int
    var valueChanged: ((PimpSegmentedControl) -> Void)? = nil
    
    init(itemz: [String], valueChanged: @escaping (PimpSegmentedControl) -> Void) {
        log.info("Going along")
        answer = 42
        self.valueChanged = valueChanged
        super.init(items: itemz)
        addTarget(nil, action: #selector(onSegmentChanged(_:)), for: UIControl.Event.valueChanged)
    }
    
    override init(frame: CGRect) {
        answer = 43
        //self.valueChanged = { _ in () }
        super.init(frame: frame)
        log.info("Dummy segment")
    }
    
    required init?(coder aDecoder: NSCoder) {
        answer = 44
        //self.valueChanged = { _ in () }
        super.init(coder: aDecoder)
        log.info("Dummy segment2")
    }
    
    @objc func onSegmentChanged(_ ctrl: PimpSegmentedControl) {
        log.info("Answer: \(answer)")
        if let cb = valueChanged {
            cb(ctrl)
        }
        //valueChanged(ctrl)
    }
    
}
