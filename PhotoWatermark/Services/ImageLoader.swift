import AppKit
import UniformTypeIdentifiers

enum ImageLoader {
    static func load(from url: URL) throws -> NSImage {
        guard let image = NSImage(contentsOf: url) else {
            throw NSError(domain: "ImageLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法加载图片"])
        }
        return image
    }
}

