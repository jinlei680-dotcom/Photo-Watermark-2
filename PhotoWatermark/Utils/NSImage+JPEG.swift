import AppKit

extension NSImage {
    func jpegData(quality: CGFloat) -> Data? {
        guard let tiff = self.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }

    func writeJPEG(to url: URL, quality: CGFloat) throws {
        guard let data = jpegData(quality: quality) else {
            throw NSError(domain: "NSImageJPEG", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法生成JPEG数据"])
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}
