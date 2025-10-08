import AppKit
import CoreGraphics

enum WatermarkRenderer {
    static func render(image: NSImage, spec: WatermarkSpec) -> NSImage {
        let targetSize = image.size
        let newImage = NSImage(size: targetSize)
        // 使用带透明通道的位图上下文
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

        // 若存在图片水印，计算其尺寸与位置后绘制
        if let wmImage = spec.imageWatermark {
            let originalWMSize = wmImage.size
            var wmSize = originalWMSize
            switch spec.imageScaleMode {
            case .percent:
                let p = max(spec.imageScalePercent, 0.01)
                wmSize = CGSize(width: max(originalWMSize.width * p / 100.0, 1),
                                height: max(originalWMSize.height * p / 100.0, 1))
            case .free:
                let w = max(spec.imageTargetWidth, 1)
                let h = max(spec.imageTargetHeight, 1)
                wmSize = CGSize(width: w, height: h)
            }

            let wmPos = WatermarkLayout.computePosition(imageSize: targetSize, watermarkSize: wmSize, spec: spec)
            let wmRect = CGRect(origin: wmPos, size: wmSize)
            // 使用 fraction 控制整体透明度
            if let cg = NSGraphicsContext.current?.cgContext {
                cg.saveGState()
                let center = CGPoint(x: wmRect.midX, y: wmRect.midY)
                cg.translateBy(x: center.x, y: center.y)
                cg.rotate(by: spec.rotationDegrees * .pi / 180.0)
                let drawRect = CGRect(x: -wmRect.size.width / 2, y: -wmRect.size.height / 2, width: wmRect.size.width, height: wmRect.size.height)
                wmImage.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: max(min(spec.imageOpacity, 1), 0))
                cg.restoreGState()
            } else {
                wmImage.draw(in: wmRect, from: .zero, operation: .sourceOver, fraction: max(min(spec.imageOpacity, 1), 0))
            }
        }

        // 配置文本属性（字体族、粗体、斜体）
        let baseFont: NSFont
        if let family = spec.fontFamily, let font = NSFont(name: family, size: spec.fontSize) {
            baseFont = font
        } else {
            baseFont = NSFont.systemFont(ofSize: spec.fontSize)
        }

        var finalFont = baseFont
        if spec.isBold {
            finalFont = NSFontManager.shared.convert(finalFont, toHaveTrait: .boldFontMask)
        }
        if spec.isItalic {
            finalFont = NSFontManager.shared.convert(finalFont, toHaveTrait: .italicFontMask)
        }

        // 颜色与透明度
        let finalColor = spec.color.withAlphaComponent(spec.opacity)

        var attrs: [NSAttributedString.Key: Any] = [
            .font: finalFont,
            .foregroundColor: finalColor
        ]

        // 阴影（可调半径、偏移、颜色、透明度）
        if spec.enableShadow {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = max(spec.shadowBlurRadius, 0)
            let shadowBaseColor = spec.shadowColor
            let shadowAlpha = max(min(spec.shadowOpacity, 1), 0)
            shadow.shadowColor = shadowBaseColor.withAlphaComponent(shadowAlpha)
            shadow.shadowOffset = NSSize(width: spec.shadowOffsetX, height: spec.shadowOffsetY)
            attrs[.shadow] = shadow
        }

        // 描边（通过 stroke 容器属性绘制轮廓）
        if spec.enableStroke {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byClipping
            attrs[.paragraphStyle] = paragraph
            attrs[.strokeColor] = spec.strokeColor
            attrs[.strokeWidth] = -spec.strokeWidth // 负值表示填充+描边
        }

        // 斜体变体缺失时的模拟：使用 obliqueness 进行倾斜
        if spec.isItalic {
            let traits = NSFontManager.shared.traits(of: finalFont)
            if !traits.contains(.italicFontMask) {
                attrs[.obliqueness] = 0.2
            }
        }

        let nsString = NSString(string: spec.text)
        let textSize = nsString.size(withAttributes: attrs)
        let position = WatermarkLayout.computePosition(imageSize: targetSize, watermarkSize: textSize, spec: spec)

        // 绘制文本（支持围绕中心旋转）
        if let cg = NSGraphicsContext.current?.cgContext {
            cg.saveGState()
            let center = CGPoint(x: position.x + textSize.width / 2, y: position.y + textSize.height / 2)
            cg.translateBy(x: center.x, y: center.y)
            cg.rotate(by: spec.rotationDegrees * .pi / 180.0)
            nsString.draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2), withAttributes: attrs)
            cg.restoreGState()
        } else {
            nsString.draw(at: position, withAttributes: attrs)
        }

        NSGraphicsContext.restoreGraphicsState()
        if let rep {
            newImage.addRepresentation(rep)
        }
        
        return newImage
    }

    // 已改为根据 spec 动态生成阴影，不再使用固定 shadow
}