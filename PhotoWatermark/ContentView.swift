import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var sourceURL: URL?
    @State private var sourceImage: NSImage?
    @State private var previewImage: NSImage?
    @State private var watermarkText: String = "© Watermark"
    @State private var fontSize: Double = 36
    @State private var position: WatermarkPosition = .bottomRight
    @State private var isDropTargetActive: Bool = false
    @State private var importedItems: [ImportedItem] = []
    @State private var selectedIndex: Int? = nil
    @State private var outputFormat: OutputFormat = .png
    // 导出相关状态
    @State private var exportDirectory: URL? = nil
    enum NamingRule: Hashable { case original, prefix, suffix }
    @State private var namingRule: NamingRule = .original
    @State private var namePrefix: String = "wm_"
    @State private var nameSuffix: String = "_watermarked"
    // JPEG 质量（0-100）
    @State private var jpegQuality: Double = 90
    // 尺寸缩放
    enum ResizeMode: Hashable { case none, width, height, percent }
    @State private var resizeMode: ResizeMode = .none
    @State private var resizeValue: Double = 100

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                ZStack {
                    // 主展示区域（图片或占位文案）
                    Group {
                        if let image = previewImage ?? sourceImage {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(minWidth: 500, minHeight: 380)
                                .border(Color.gray.opacity(0.2))
                        } else {
                            VStack(spacing: 8) {
                                Text("拖拽图片到此或点击‘打开图片’")
                                Text("支持 JPG/PNG/HEIC/TIFF/BMP")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(minWidth: 500, minHeight: 380)
                            .border(Color.gray.opacity(0.2))
                        }
                    }

                    // 拖拽高亮指示
                    if isDropTargetActive {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor, lineWidth: 2)
                            .padding(4)
                            .transition(.opacity)
                    }
                }
                // 缩略图与文件名列表（水平滚动）
                if !importedItems.isEmpty {
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 8) {
                            ForEach(importedItems.indices, id: \.self) { idx in
                                let item = importedItems[idx]
                                VStack(spacing: 6) {
                                    Image(nsImage: item.image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 80)
                                        .clipped()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(selectedIndex == idx ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: selectedIndex == idx ? 2 : 1)
                                        )
                                    Text(item.displayName)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .font(.caption)
                                }
                                .onTapGesture { selectItem(at: idx) }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            // 拖拽导入（支持 Finder 文件与图片对象）
            .onDrop(of: [UTType.fileURL, UTType.image], isTargeted: $isDropTargetActive) { providers in
                return handleDrop(providers)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("操作")
                    .font(.headline)

                HStack(spacing: 12) {
                    Button("打开图片", action: openImage)
                    Button("取消图片", action: cancelImage)
                        .disabled((sourceImage == nil) && (previewImage == nil))
                    Button("预览水印", action: previewWatermark)
                        .disabled(sourceImage == nil || watermarkText.isEmpty)
                    Button("保存图片", action: saveImage)
                        .disabled(previewImage == nil)
                }

                TextField("水印文本", text: $watermarkText)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text("字号")
                    Slider(value: $fontSize, in: 8...200)
                    Text("\(Int(fontSize))")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .leading)
                }

                Picker("位置", selection: $position) {
                    Text("左上").tag(WatermarkPosition.topLeft)
                    Text("居中").tag(WatermarkPosition.center)
                    Text("右下").tag(WatermarkPosition.bottomRight)
                }
                .pickerStyle(.segmented)

                Picker("输出格式", selection: $outputFormat) {
                    Text("PNG").tag(OutputFormat.png)
                    Text("JPEG").tag(OutputFormat.jpeg)
                }
                .pickerStyle(.segmented)

                // 输出目录选择
                HStack {
                    Text("输出目录")
                    if let dir = exportDirectory {
                        Text(dir.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("未选择")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("选择文件夹", action: chooseOutputFolder)
                }

                // 命名规则
                Picker("命名规则", selection: $namingRule) {
                    Text("保留原文件名").tag(NamingRule.original)
                    Text("添加前缀").tag(NamingRule.prefix)
                    Text("添加后缀").tag(NamingRule.suffix)
                }
                .pickerStyle(.segmented)

                if namingRule == .prefix {
                    TextField("自定义前缀", text: $namePrefix)
                        .textFieldStyle(.roundedBorder)
                }
                if namingRule == .suffix {
                    TextField("自定义后缀", text: $nameSuffix)
                        .textFieldStyle(.roundedBorder)
                }

                // JPEG 质量（仅在 JPEG 格式下显示）
                if outputFormat == .jpeg {
                    HStack {
                        Text("JPEG质量")
                        Slider(value: $jpegQuality, in: 0...100)
                        Text("\(Int(jpegQuality))")
                            .monospacedDigit()
                            .frame(width: 40, alignment: .leading)
                    }
                }

                // 尺寸缩放
                Picker("尺寸", selection: $resizeMode) {
                    Text("不缩放").tag(ResizeMode.none)
                    Text("按宽度").tag(ResizeMode.width)
                    Text("按高度").tag(ResizeMode.height)
                    Text("按百分比").tag(ResizeMode.percent)
                }
                .pickerStyle(.segmented)

                if resizeMode == .width {
                    HStack {
                        Text("宽度(px)")
                        TextField("", value: $resizeValue, format: .number)
                            .frame(width: 80)
                        if let img = previewImage ?? sourceImage {
                            Text("原始宽度：\(Int(img.size.width))")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if resizeMode == .height {
                    HStack {
                        Text("高度(px)")
                        TextField("", value: $resizeValue, format: .number)
                            .frame(width: 80)
                        if let img = previewImage ?? sourceImage {
                            Text("原始高度：\(Int(img.size.height))")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if resizeMode == .percent {
                    HStack {
                        Text("百分比")
                        Slider(value: $resizeValue, in: 10...400)
                        Text("\(Int(resizeValue))%")
                            .monospacedDigit()
                            .frame(width: 60, alignment: .leading)
                    }
                }

                Spacer()

                Text("提示：先‘打开图片’，输入水印后‘预览水印’，确认后‘保存图片’。")
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 320)
            .padding(12)
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            print("[ContentView] appeared: sourceImage=\(sourceImage != nil), previewImage=\(previewImage != nil)")
        }
    }

    struct ImportedItem: Identifiable {
        let id = UUID()
        let url: URL?
        let image: NSImage
        let name: String?
        var displayName: String {
            if let n = name, !n.isEmpty { return n }
            if let u = url { return u.lastPathComponent }
            return "未命名图片"
        }
    }

    // 处理拖拽导入的文件或图片
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        // 优先处理文件 URL（可读取 EXIF）
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let error = error { print("[Drop] fileURL load error: \(error)") }
                guard let item = item else { return }
                var url: URL?
                if let u = item as? URL {
                    url = u
                } else if let data = item as? Data {
                    // 尝试从 data 表示的 URL 恢复
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let str = item as? String {
                    url = URL(fileURLWithPath: str)
                }
                guard let fileURL = url else { print("[Drop] unable to resolve URL from item: \(item)"); return }
                DispatchQueue.main.async {
                    self.importURLs([fileURL])
                }
            }
            return true
        }

        // 其次处理直接拖拽的图片数据（无法读取 EXIF，尽量提取名称）
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) {
            var derivedName: String? = provider.suggestedName
            // 尝试获取临时文件表示以读取文件名
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
                if let url { derivedName = url.lastPathComponent }
                // 加载图片数据
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                    if let error = error { print("[Drop] image data load error: \(error)") }
                    guard let data = data, let image = NSImage(data: data) else { return }
                    DispatchQueue.main.async {
                        let item = ImportedItem(url: nil, image: image, name: derivedName)
                        self.appendImported(item)
                        self.selectItem(at: importedItems.count - 1)
                        print("[Drop] loaded NSImage from data, name=\(derivedName ?? "nil")")
                    }
                }
            }
            return true
        }
        return false
    }

    private func openImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.png, UTType.jpeg, UTType.heic, UTType.tiff, UTType.bmp]
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        let result = panel.runModal()
        print("[OpenPanel] result=\(result == .OK ? "OK" : "Cancel"), urls=\(panel.urls)")
        if result == .OK {
            importURLs(panel.urls)
        }
    }

    private func previewWatermark() {
        guard let image = sourceImage else { return }
        let spec = WatermarkSpec(text: watermarkText, fontSize: CGFloat(fontSize), margin: 24, position: position)
        let result = WatermarkRenderer.render(image: image, spec: spec)
        self.previewImage = result
    }

    private func saveImage() {
        guard let baseImage = previewImage ?? sourceImage else { return }
        // 计算目标目录
        var targetDir: URL
        if let dir = exportDirectory {
            targetDir = dir
        } else if let src = sourceURL {
            targetDir = OutputManager.outputDirectory(for: src)
        } else {
            targetDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop/PhotoWatermark-Output")
        }
        // 禁止导出到原文件夹（默认）
        if let src = sourceURL {
            let srcDir = src.deletingLastPathComponent()
            if srcDir.standardizedFileURL == targetDir.standardizedFileURL {
                let alert = NSAlert()
                alert.messageText = "禁止导出到原文件夹"
                alert.informativeText = "为防止覆盖原图，请选择其他输出目录。"
                alert.runModal()
                return
            }
        }

        // 计算文件名
        let baseName = (sourceURL?.deletingPathExtension().lastPathComponent) ?? "PhotoWatermark"
        let fileName: String
        switch namingRule {
        case .original:
            fileName = baseName
        case .prefix:
            fileName = namePrefix + baseName
        case .suffix:
            fileName = baseName + nameSuffix
        }
        let ext = (outputFormat == .png) ? "png" : "jpg"
        let outURL = targetDir.appendingPathComponent(fileName).appendingPathExtension(ext)

        // 计算尺寸
        let originalSize = baseImage.size
        var targetSize = originalSize
        switch resizeMode {
        case .none:
            break
        case .width:
            let w = max(CGFloat(resizeValue), 1)
            let scale = w / max(originalSize.width, 1)
            targetSize = CGSize(width: w, height: max(originalSize.height * scale, 1))
        case .height:
            let h = max(CGFloat(resizeValue), 1)
            let scale = h / max(originalSize.height, 1)
            targetSize = CGSize(width: max(originalSize.width * scale, 1), height: h)
        case .percent:
            let p = max(CGFloat(resizeValue) / 100.0, 0.01)
            targetSize = CGSize(width: max(originalSize.width * p, 1), height: max(originalSize.height * p, 1))
        }

        // 执行缩放（如需）
        let imageToSave: NSImage
        if targetSize != originalSize, let resized = baseImage.resized(to: targetSize) {
            imageToSave = resized
        } else {
            imageToSave = baseImage
        }

        // 写入文件
        do {
            try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
            if outputFormat == .png {
                try imageToSave.writePNG(to: outURL)
            } else {
                let q = max(min(jpegQuality, 100), 0) / 100.0
                try imageToSave.writeJPEG(to: outURL, quality: CGFloat(q))
            }
            print("[Save] wrote: \(outURL.path)")
            // 成功提示弹窗
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "添加水印成功"
            alert.informativeText = "已保存到：\(outURL.path)"
            alert.addButton(withTitle: "确定")
            alert.runModal()
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func cancelImage() {
        // 清空当前图片、预览与缩略图，并重置默认水印文本
        print("[Action] cancelImage: clearing source, preview, and thumbnails")
        self.sourceURL = nil
        self.sourceImage = nil
        self.previewImage = nil
        self.watermarkText = "© Watermark"
        self.importedItems.removeAll()
        self.selectedIndex = nil
    }

    private func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "选择"
        let result = panel.runModal()
        if result == .OK, let url = panel.url {
            // 默认禁止导出到原文件夹
            if let src = sourceURL {
                let srcDir = src.deletingLastPathComponent()
                if srcDir.standardizedFileURL == url.standardizedFileURL {
                    let alert = NSAlert()
                    alert.messageText = "禁止导出到原文件夹"
                    alert.informativeText = "为防止覆盖原图，请选择其他输出目录。"
                    alert.runModal()
                    return
                }
            }
            exportDirectory = url
        }
    }

    // MARK: - Batch Import Helpers
    private func importURLs(_ urls: [URL]) {
        // 展开目录并筛选支持的图片扩展名
        let targets = gatherImageURLs(from: urls)
        var lastSelectedIndex: Int? = nil
        for url in targets {
            // 去重：按 URL 检查是否已存在
            if importedItems.contains(where: { $0.url == url }) { continue }
            do {
                let image = try ImageLoader.load(from: url)
                let item = ImportedItem(url: url, image: image, name: nil)
                appendImported(item)
                lastSelectedIndex = importedItems.count - 1
                // 设置默认水印文本（EXIF 日期或回退）
                let exif = ExifReader.read(from: url)
                if let date = exif.dateText, !date.isEmpty { self.watermarkText = date } else { self.watermarkText = "© Watermark" }
                print("[Import] added: \(url.path)")
            } catch {
                NSAlert(error: error).runModal()
            }
        }
        if let idx = lastSelectedIndex { selectItem(at: idx) }
    }

    private func gatherImageURLs(from urls: [URL]) -> [URL] {
        let allowedExts: Set<String> = ["jpg","jpeg","png","heic","tiff","bmp"]
        var results: [URL] = []
        let fm = FileManager.default
        for url in urls {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                // 递归遍历目录
                if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                    for case let fileURL as URL in enumerator {
                        if allowedExts.contains(fileURL.pathExtension.lowercased()) {
                            results.append(fileURL)
                        }
                    }
                }
            } else {
                if allowedExts.contains(url.pathExtension.lowercased()) {
                    results.append(url)
                }
            }
        }
        return results
    }

    private func appendImported(_ item: ImportedItem) {
        importedItems.append(item)
    }

    private func selectItem(at idx: Int) {
        guard importedItems.indices.contains(idx) else { return }
        selectedIndex = idx
        let item = importedItems[idx]
        self.sourceURL = item.url
        self.sourceImage = item.image
        self.previewImage = nil
        // 如果有 URL，尝试同步 EXIF 日期为默认水印
        if let url = item.url {
            let exif = ExifReader.read(from: url)
            if let date = exif.dateText, !date.isEmpty { self.watermarkText = date }
        }
    }
}