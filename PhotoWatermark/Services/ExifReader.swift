import AppKit
import ImageIO

struct ExifInfo {
    let dateText: String?
}

enum ExifReader {
    static func read(from url: URL) -> ExifInfo {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] else {
            return ExifInfo(dateText: nil)
        }
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let dateOriginal = exif?[kCGImagePropertyExifDateTimeOriginal] as? String
        // TODO: 解析为 YYYY-MM-DD
        return ExifInfo(dateText: dateOriginal)
    }
}