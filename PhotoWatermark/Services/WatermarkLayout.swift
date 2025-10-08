import CoreGraphics
import AppKit

enum WatermarkPosition {
    case topLeft
    case topCenter
    case topRight
    case centerLeft
    case center
    case centerRight
    case bottomLeft
    case bottomCenter
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
    let useManualPosition: Bool
    let manualX: CGFloat
    let manualY: CGFloat
    let rotationDegrees: CGFloat
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
        // 若启用手动定位，manualX/manualY 表示水印中心坐标（以左下为原点）
        if spec.useManualPosition {
            return CGPoint(
                x: spec.manualX - watermarkSize.width / 2,
                y: spec.manualY - watermarkSize.height / 2
            )
        }
        switch spec.position {
        case .topLeft:
            return CGPoint(x: spec.margin, y: imageSize.height - watermarkSize.height - spec.margin)
        case .topCenter:
            return CGPoint(x: (imageSize.width - watermarkSize.width) / 2, y: imageSize.height - watermarkSize.height - spec.margin)
        case .topRight:
            return CGPoint(x: imageSize.width - watermarkSize.width - spec.margin, y: imageSize.height - watermarkSize.height - spec.margin)
        case .centerLeft:
            return CGPoint(x: spec.margin, y: (imageSize.height - watermarkSize.height) / 2)
        case .center:
            return CGPoint(x: (imageSize.width - watermarkSize.width) / 2, y: (imageSize.height - watermarkSize.height) / 2)
        case .centerRight:
            return CGPoint(x: imageSize.width - watermarkSize.width - spec.margin, y: (imageSize.height - watermarkSize.height) / 2)
        case .bottomLeft:
            return CGPoint(x: spec.margin, y: spec.margin)
        case .bottomCenter:
            return CGPoint(x: (imageSize.width - watermarkSize.width) / 2, y: spec.margin)
        case .bottomRight:
            return CGPoint(x: imageSize.width - watermarkSize.width - spec.margin, y: spec.margin)
        }
    }
}