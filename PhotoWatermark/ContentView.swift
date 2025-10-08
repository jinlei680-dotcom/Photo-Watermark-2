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
                                Text("支持 JPG/PNG/HEIC")
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
        var displayName: String {
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

        // 其次处理直接拖拽的图片数据（无法读取 EXIF，使用回退文案）
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                if let error = error { print("[Drop] image data load error: \(error)") }
                guard let data = data, let image = NSImage(data: data) else { return }
                DispatchQueue.main.async {
                    let item = ImportedItem(url: nil, image: image)
                    self.appendImported(item)
                    self.selectItem(at: importedItems.count - 1)
                    print("[Drop] loaded NSImage from data")
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
        guard let image = previewImage else { return }
        let defaultURL: URL
        if let src = sourceURL {
            defaultURL = OutputManager.outputURL(for: src).deletingPathExtension().appendingPathExtension("png")
        } else {
            defaultURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop/PhotoWatermark.png")
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultURL.lastPathComponent
        panel.directoryURL = defaultURL.deletingLastPathComponent()
        let result = panel.runModal()
        print("[SavePanel] result=\(result == .OK ? "OK" : "Cancel"), url=\(String(describing: panel.url))")
        if result == .OK, let url = panel.url {
            do {
                try image.writePNG(to: url)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    private func cancelImage() {
        // 清空当前图片与预览，并重置默认水印文本
        print("[Action] cancelImage: clearing source & preview")
        self.sourceURL = nil
        self.sourceImage = nil
        self.previewImage = nil
        self.watermarkText = "© Watermark"
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
                let item = ImportedItem(url: url, image: image)
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