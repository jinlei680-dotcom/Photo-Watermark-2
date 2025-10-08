import AppKit

extension NSImage {
    func resized(to targetSize: CGSize) -> NSImage? {
        let newImage = NSImage(size: targetSize)
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
        guard let rep else { return nil }
        let ctx = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        self.draw(in: CGRect(origin: .zero, size: targetSize))
        NSGraphicsContext.restoreGraphicsState()
        newImage.addRepresentation(rep)
        return newImage
    }
}