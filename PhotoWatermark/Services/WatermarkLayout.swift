import CoreGraphics
import AppKit

enum WatermarkPosition {
    case topLeft
    case center
    case bottomRight
}

enum OutputFormat {
    case png
    case jpeg
}

enum ImageScaleMode {
    case percent
    case free
}

struct WatermarkSpec {
    // 文本水印
    let text: String
    let fontSize: CGFloat
    let margin: CGFloat
    let position: WatermarkPosition
    let fontFamily: String?
    let isBold: Bool
    let isItalic: Bool
    let color: NSColor
    let opacity: CGFloat
    let enableShadow: Bool
    let shadowBlurRadius: CGFloat
    let shadowOffsetX: CGFloat
    let shadowOffsetY: CGFloat
    let shadowColor: NSColor
    let shadowOpacity: CGFloat
    let enableStroke: Bool
    let strokeWidth: CGFloat
    let strokeColor: NSColor

    // 图片水印（可选）
    let imageWatermark: NSImage?
    let imageOpacity: CGFloat // 0.0 - 1.0
    let imageScaleMode: ImageScaleMode
    let imageScalePercent: CGFloat // 0.01 - 10.0（1% - 1000%）
    let imageTargetWidth: CGFloat
    let imageTargetHeight: CGFloat
}

enum WatermarkLayout {
    static func computePosition(imageSize: CGSize, watermarkSize: CGSize, spec: WatermarkSpec) -> CGPoint {
        switch spec.position {
        case .topLeft:
            return CGPoint(x: spec.margin, y: imageSize.height - watermarkSize.height - spec.margin)
        case .center:
            return CGPoint(x: (imageSize.width - watermarkSize.width) / 2, y: (imageSize.height - watermarkSize.height) / 2)
        case .bottomRight:
            return CGPoint(x: imageSize.width - watermarkSize.width - spec.margin, y: spec.margin)
        }
    }
}