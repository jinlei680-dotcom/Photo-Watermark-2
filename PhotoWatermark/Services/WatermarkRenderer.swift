import AppKit
import CoreGraphics

enum WatermarkRenderer {
    static func render(image: NSImage, spec: WatermarkSpec) -> NSImage {
        let targetSize = image.size
        let newImage = NSImage(size: targetSize)
        // 使用带透明通道的位图上下文
        let rect = CGRect(origin: .zero, size: targetSize)
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(targetSize.width),
            pixelsHigh: Int(targetSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        if let rep {
            let ctx = NSGraphicsContext(bitmapImageRep: rep)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = ctx
        }

        // 绘制原图
        image.draw(in: CGRect(origin: .zero, size: targetSize))

        // 配置文本属性
        let font = NSFont.systemFont(ofSize: spec.fontSize, weight: .semibold)
        let color = NSColor.white.withAlphaComponent(0.85)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .shadow: textShadow()
        ]

        let nsString = NSString(string: spec.text)
        let textSize = nsString.size(withAttributes: attrs)
        let position = WatermarkLayout.computePosition(imageSize: targetSize, textSize: textSize, spec: spec)

        // 绘制文本
        nsString.draw(at: position, withAttributes: attrs)

        NSGraphicsContext.restoreGraphicsState()
        if let rep {
            newImage.addRepresentation(rep)
        }
        
        return newImage
    }

    private static func textShadow() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 2
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowOffset = NSSize(width: 1, height: -1)
        return shadow
    }
}