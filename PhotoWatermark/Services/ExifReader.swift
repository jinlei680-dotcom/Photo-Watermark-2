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
        let formatted = Self.formatEXIFDate(dateOriginal)
        return ExifInfo(dateText: formatted)
    }

    // 将常见 EXIF 日期字符串转换为 YYYY-MM-DD
    private static func formatEXIFDate(_ raw: String?) -> String? {
        guard let raw = raw, !raw.isEmpty else { return nil }
        // 常见格式："yyyy:MM:dd HH:mm:ss"
        if raw.count >= 10 {
            let prefix10 = String(raw.prefix(10)) // yyyy:MM:dd
            let parts = prefix10.split(separator: ":")
            if parts.count == 3 {
                let y = parts[0], m = parts[1], d = parts[2]
                if y.count == 4 && m.count == 2 && d.count == 2 {
                    return "\(y)-\(m)-\(d)"
                }
            }
        }
        // 兼容 ISO 格式：yyyy-MM-dd 开头
        if let range = raw.range(of: "^\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) {
            return String(raw[range])
        }
        return nil
    }
}
