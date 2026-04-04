import UIKit

protocol Shimmerable: AnyObject {
    var layer: CALayer { get }
    var bounds: CGRect { get }
}

extension Shimmerable {
    func startShimmer() {
        stopShimmer()
        let gradient = CAGradientLayer()
        gradient.name = "shimmerLayer"
        gradient.frame = CGRect(x: -bounds.width, y: 0,
                                width: bounds.width * 3, height: bounds.height)
        gradient.colors = [
            UIColor.mbSurfaceAlt.cgColor,
            UIColor(white: 1, alpha: 0.15).cgColor,
            UIColor.mbSurfaceAlt.cgColor
        ]
        gradient.locations = [0, 0.5, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradient)

        let anim = CABasicAnimation(keyPath: "position.x")
        anim.fromValue  = -bounds.width
        anim.toValue    = bounds.width * 2
        anim.duration   = 1.4
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        gradient.add(anim, forKey: "shimmer")
    }

    func stopShimmer() {
        layer.sublayers?.filter { $0.name == "shimmerLayer" }.forEach { $0.removeFromSuperlayer() }
    }
}
