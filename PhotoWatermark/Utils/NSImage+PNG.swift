import AppKit

extension NSImage {
    func pngData() -> Data? {
        guard let tiff = self.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    func writePNG(to url: URL) throws {
        guard let data = pngData() else {
            throw NSError(domain: "NSImagePNG", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法生成PNG数据"])
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}