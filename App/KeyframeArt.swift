import UIKit

// Original procedural artwork. No network, model weights, stock assets or watermark.
enum KeyframeArt {
    static func image(index: Int, size: CGSize = CGSize(width: 1080, height: 1920)) -> UIImage {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let c = context.cgContext; let w = size.width; let h = size.height
            let palette = [UIColor(red: 0.03, green: 0.14, blue: 0.16, alpha: 1),
                           UIColor(red: 0.49, green: 0.34, blue: 0.21, alpha: 1)]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: palette.map(\.cgColor) as CFArray, locations: [0, 1])!
            c.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: w, y: h), options: [])
            let sunX = w * (0.25 + Double(index % 4) * 0.15)
            c.setFillColor(UIColor(red: 1, green: 0.72, blue: 0.36, alpha: 0.9).cgColor)
            c.fillEllipse(in: CGRect(x: sunX, y: h * 0.25, width: w * 0.19, height: w * 0.19))
            for layer in 0..<5 {
                let base = h * (0.4 + Double(layer) * 0.12)
                let path = CGMutablePath(); path.move(to: CGPoint(x: -w * 0.2, y: h))
                for point in 0...8 {
                    let x = Double(point) / 7 * w
                    let rise = sin(Double(point * 3 + layer * 5 + index) * 1.3) * h * 0.10
                    path.addLine(to: CGPoint(x: x, y: base + rise))
                }
                path.addLine(to: CGPoint(x: w * 1.2, y: h)); path.closeSubpath()
                let shade = Double(layer) * 0.025
                c.setFillColor(UIColor(red: 0.13 - shade, green: 0.25 - shade, blue: 0.25 - shade, alpha: 1).cgColor)
                c.addPath(path); c.fillPath()
            }
            let road = UIBezierPath()
            road.move(to: CGPoint(x: w * 0.56, y: h * 0.6))
            road.addCurve(to: CGPoint(x: w * 0.27, y: h), controlPoint1: CGPoint(x: w * 0.2, y: h * 0.73), controlPoint2: CGPoint(x: w * 0.87, y: h * 0.78))
            UIColor(red: 0.49, green: 0.54, blue: 0.48, alpha: 0.6).setStroke(); road.lineWidth = w * 0.025; road.stroke()
            UIColor(red: 0.94, green: 0.72, blue: 0.39, alpha: 0.8).setStroke(); road.lineWidth = w * 0.003; road.stroke()
        }
    }
}
