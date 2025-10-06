import Foundation

enum OutputManager {
    static func outputDirectory(for source: URL) -> URL {
        let parent = source.deletingLastPathComponent()
        let dir = parent.appendingPathComponent(parent.lastPathComponent + "_watermark")
        return dir
    }

    static func outputURL(for source: URL) -> URL {
        let dir = outputDirectory(for: source)
        let name = source.deletingPathExtension().lastPathComponent + "_watermark"
        return dir.appendingPathComponent(name).appendingPathExtension(source.pathExtension)
    }
}