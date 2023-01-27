import Foundation

class Colors {
    static let RGB_MAX: CGFloat = 255
    static let NO_TRANSPARENCY: CGFloat = 1
    
    static func rgb(_ red: Int, green: Int, blue: Int, alpha: CGFloat = NO_TRANSPARENCY) -> UIColor {
        return UIColor(red: CGFloat(red) / RGB_MAX, green: CGFloat(green) / RGB_MAX, blue: CGFloat(blue) / RGB_MAX, alpha: alpha)
    }
}
