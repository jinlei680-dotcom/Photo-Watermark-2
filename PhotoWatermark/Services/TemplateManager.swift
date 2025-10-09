import Foundation
import AppKit

// 颜色持久化DTO
struct ColorDTO: Codable {
    let r: Double
    let g: Double
    let b: Double
    let a: Double
}

// 水印设置持久化DTO（覆盖所有与水印相关的参数）
struct WatermarkSettingsDTO: Codable {
    // 类型与内容
    let watermarkType: String // "text" | "image"
    let watermarkText: String

    // 文本样式
    let fontSize: Double
    let fontFamily: String
    let isBold: Bool
    let isItalic: Bool
    let fontColor: ColorDTO
    let opacity: Double // 0-100

    // 位置与旋转
    let position: String // 对应 WatermarkPosition 枚举的字符串
    let useManualPosition: Bool
    let manualX: Double
    let manualY: Double
    let rotationDegrees: Double

    // 阴影
    let enableShadow: Bool
    let shadowBlurRadius: Double
    let shadowOffsetX: Double
    let shadowOffsetY: Double
    let shadowColor: ColorDTO
    let shadowOpacity: Double // 0-100

    // 描边
    let enableStroke: Bool
    let strokeWidth: Double
    let strokeColor: ColorDTO

    // 图片水印
    let imageWatermarkPath: String? // 可选：图片水印文件路径
    let imageOpacity: Double // 0-100
    let imageScaleMode: String // "percent" | "free"
    let imageScalePercent: Double
    let imageTargetWidth: Double
    let imageTargetHeight: Double

    // 额外持久化：边距与导出相关（为兼容旧版本，均设置为可选）
    let margin: Double?
    let outputFormat: String? // "png" | "jpeg"
    let namingRule: String? // "original" | "prefix" | "suffix"
    let namePrefix: String?
    let nameSuffix: String?
    let jpegQuality: Double?
    let resizeMode: String? // "none" | "width" | "height" | "percent"
    let resizeValue: Double?
    let exportDirectoryPath: String?
}

enum TemplateManager {
    // 目录结构
    private static var appSupportDir: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("PhotoWatermark", isDirectory: true)
    }
    private static var templatesDir: URL { appSupportDir.appendingPathComponent("Templates", isDirectory: true) }
    private static var lastSessionFile: URL { appSupportDir.appendingPathComponent("lastSession.json") }
    private static var configFile: URL { appSupportDir.appendingPathComponent("config.json") }

    struct AppConfig: Codable { var defaultTemplateName: String? }

    static func ensureDirs() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: appSupportDir.path) {
            try? fm.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        }
        if !fm.fileExists(atPath: templatesDir.path) {
            try? fm.createDirectory(at: templatesDir, withIntermediateDirectories: true)
        }
    }

    // 列出模板名称（按 .json 文件名）
    static func listTemplates() -> [String] {
        ensureDirs()
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: templatesDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return [] }
        return items.filter { $0.pathExtension.lowercased() == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }

    // 保存模板
    static func saveTemplate(name: String, settings: WatermarkSettingsDTO) throws {
        ensureDirs()
        let url = templatesDir.appendingPathComponent(name).appendingPathExtension("json")
        let data = try JSONEncoder().encode(settings)
        try data.write(to: url, options: .atomic)
    }

    // 加载模板
    static func loadTemplate(name: String) -> WatermarkSettingsDTO? {
        ensureDirs()
        let url = templatesDir.appendingPathComponent(name).appendingPathExtension("json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WatermarkSettingsDTO.self, from: data)
    }

    // 删除模板
    static func deleteTemplate(name: String) throws {
        ensureDirs()
        let url = templatesDir.appendingPathComponent(name).appendingPathExtension("json")
        try FileManager.default.removeItem(at: url)
    }

    // 默认模板配置
    static func getConfig() -> AppConfig {
        ensureDirs()
        guard let data = try? Data(contentsOf: configFile), let cfg = try? JSONDecoder().decode(AppConfig.self, from: data) else { return AppConfig(defaultTemplateName: nil) }
        return cfg
    }
    static func setDefaultTemplate(name: String?) {
        ensureDirs()
        let cfg = AppConfig(defaultTemplateName: name)
        if let data = try? JSONEncoder().encode(cfg) {
            try? data.write(to: configFile, options: .atomic)
        }
    }

    // 会话保存/加载
    static func saveLastSession(settings: WatermarkSettingsDTO) {
        ensureDirs()
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: lastSessionFile, options: .atomic)
        }
    }
    static func loadLastSession() -> WatermarkSettingsDTO? {
        ensureDirs()
        guard let data = try? Data(contentsOf: lastSessionFile) else { return nil }
        return try? JSONDecoder().decode(WatermarkSettingsDTO.self, from: data)
    }

    // 启动时加载：优先 lastSession；否则默认模板；都没有则返回 nil
    static func loadLastOrDefault() -> WatermarkSettingsDTO? {
        if let last = loadLastSession() { return last }
        let cfg = getConfig()
        if let name = cfg.defaultTemplateName, let dto = loadTemplate(name: name) {
            return dto
        }
        return nil
    }

    // 编解码辅助
    static func encodeColor(_ color: NSColor) -> ColorDTO {
        // 转 sRGB 空间，确保 r/g/b/a 可用
        let c = color.usingColorSpace(.sRGB) ?? color
        return ColorDTO(r: Double(c.redComponent), g: Double(c.greenComponent), b: Double(c.blueComponent), a: Double(c.alphaComponent))
    }
    static func decodeColor(_ dto: ColorDTO) -> NSColor {
        return NSColor(srgbRed: CGFloat(dto.r), green: CGFloat(dto.g), blue: CGFloat(dto.b), alpha: CGFloat(dto.a))
    }

    static func encodePosition(_ pos: WatermarkPosition) -> String {
        switch pos {
        case .topLeft: return "topLeft"
        case .topCenter: return "topCenter"
        case .topRight: return "topRight"
        case .centerLeft: return "centerLeft"
        case .center: return "center"
        case .centerRight: return "centerRight"
        case .bottomLeft: return "bottomLeft"
        case .bottomCenter: return "bottomCenter"
        case .bottomRight: return "bottomRight"
        }
    }
    static func decodePosition(_ s: String) -> WatermarkPosition {
        switch s {
        case "topLeft": return .topLeft
        case "topCenter": return .topCenter
        case "topRight": return .topRight
        case "centerLeft": return .centerLeft
        case "center": return .center
        case "centerRight": return .centerRight
        case "bottomLeft": return .bottomLeft
        case "bottomCenter": return .bottomCenter
        default: return .bottomRight
        }
    }

    static func encodeScaleMode(_ m: ImageScaleMode) -> String { m == .percent ? "percent" : "free" }
    static func decodeScaleMode(_ s: String) -> ImageScaleMode { s == "percent" ? .percent : .free }
}