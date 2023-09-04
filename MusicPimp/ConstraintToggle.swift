
import Foundation

class ConstraintToggle {
    let constraints: [NSLayoutConstraint]
    let defaults: [CGFloat]
    
    init(constraints: [NSLayoutConstraint]) {
        self.constraints = constraints
        self.defaults = constraints.map { $0.constant }
    }
    
    func hide() {
        constraints.forEach { $0.constant = 0 }
    }
    
    func show() {
        for (constraint, defaultValue) in zip(constraints, defaults) {
            constraint.constant = defaultValue
        }
    }
}
