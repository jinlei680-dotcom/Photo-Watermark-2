import CoreGraphics

enum WatermarkPosition {
    case topLeft
    case center
    case bottomRight
}

struct WatermarkSpec {
    let text: String
    let fontSize: CGFloat
    let margin: CGFloat
    let position: WatermarkPosition
}

enum WatermarkLayout {
    static func computePosition(imageSize: CGSize, textSize: CGSize, spec: WatermarkSpec) -> CGPoint {
        switch spec.position {
        case .topLeft:
            return CGPoint(x: spec.margin, y: imageSize.height - textSize.height - spec.margin)
        case .center:
            return CGPoint(x: (imageSize.width - textSize.width) / 2, y: (imageSize.height - textSize.height) / 2)
        case .bottomRight:
            return CGPoint(x: imageSize.width - textSize.width - spec.margin, y: spec.margin)
        }
    }
}