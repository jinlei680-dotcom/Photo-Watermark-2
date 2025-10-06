# Photo Watermark 原生 macOS 设计说明（SwiftUI + AppKit，Zip分发，右键放行）

## 1. 目标与原则
- 目标：用户从仓库下载 `zip`，解压得到 `.app`，在 Finder 右键→打开 后即可运行；无需额外安装任何运行时或库。
- 原则：
  - 完全依赖 macOS 系统框架（`ImageIO`、`CoreGraphics`、`UniformTypeIdentifiers`、`AppKit/SwiftUI`）。
  - 生成通用二进制（`arm64 + x86_64`），不强制要求证书与公证；后续如需“直接双击运行”再补充签名与公证。
  - 预览与导出一致的绘制逻辑；不覆盖原图，保存到 `原目录名_watermark` 子目录。

## 2. 技术栈
- 语言与框架：Swift 5.9+，SwiftUI（主界面）+ AppKit（文件对话框、颜色面板桥接）。
- 图像与 EXIF：`ImageIO`（`CGImageSourceCopyProperties`），`CoreGraphics`/`CoreImage`（渲染、合成）。
- 文件类型与路径：`UniformTypeIdentifiers (UTType)`，`FileManager`。
- 打包与分发：Xcode 构建通用 `.app`；使用 `ditto` 压缩为 `zip` 分发；无证书/未公证情况下通过右键打开或 `xattr` 放行。

## 3. 架构概览
- 分层：
  - UI 层：SwiftUI 视图与状态管理（`ObservableObject`）。
  - 服务层：EXIF 读取、坐标计算、水印绘制、文件保存与输出目录策略。
  - 系统桥接：AppKit/系统框架封装（打开文件、颜色选择、目录权限）。
- 关键原则：预览与导出共用同一水印布局算法与文本度量逻辑。

## 4. 模块与职责
- `AppState`（`ObservableObject`）：当前图片、EXIF 拍摄日期、预览设置（字体大小、颜色、位置、边距）、状态消息。
- `ImageLoader`：加载图片为 `NSImage`/`CGImage`，支持 `JPEG/JPG/PNG/HEIC`（系统原生）。
- `ExifReader`：使用 `CGImageSourceCopyProperties` 读取 `DateTimeOriginal`，回退 `CreateDate/ModifyDate`，产出 `Date → YYYY-MM-DD` 文本。
- `WatermarkLayout`：根据图片尺寸、文本尺寸、位置枚举（左上/居中/右下）、边距计算绘制坐标。
- `WatermarkRenderer`：
  - 预览：在 SwiftUI 覆盖层绘制（`Canvas`/`Text` + 坐标），所见即所得。
  - 导出：用 `CoreGraphics` 将文本绘制到位图（`CGContext`），生成新图片。
- `OutputManager`：构造输出目录 `原目录名_watermark`；生成文件名 `原文件名_watermark.ext`，冲突时追加序号。
- `ErrorPresenter`：用户可读错误弹窗（无 EXIF、权限不足、空间不足等）。

## 5. UI 设计（SwiftUI）
- 布局：`NavigationSplitView` 或 `HStack`（左侧预览，右侧设置面板）。
- 顶部工具栏：`打开`、`保存`、`帮助`。
- 右侧设置：
  - 拍摄日期文本（只读，EXIF 解析；无则提供“选择日期”按钮）。
  - 字体大小（默认 24，范围 12–96）。
  - 颜色选择器（默认白色）。
  - 位置选择（左上、居中、右下）。
  - 边距（默认 16 px）。
- 状态栏：显示解析状态、输出目录、保存结果。

## 6. 水印绘制与坐标算法
- 文本度量：
  - 预览：`Text` + `GeometryReader` 或在 `Canvas` 中使用 `CoreText`/`AttributedString` 计算边界。
  - 导出：`CTLine`/`CoreText` 或 `NSAttributedString` 在 `CGContext` 上绘制，使用字体 ascent/descent 精确定位。
- 坐标计算：
  - `TOP_LEFT`：`(margin, margin + ascent)`。
  - `CENTER`：`((W - textW)/2, (H - textH)/2 + ascent)`。
  - `BOTTOM_RIGHT`：`(W - textW - margin, H - textH - margin + ascent)`。
- 渲染：开启文本抗锯齿与插值；必要时可加轻微阴影/描边提升可读性（后续可选）。

## 7. EXIF 解析策略
- 从 `CGImageSource` 属性中读取 `kCGImagePropertyExifDictionary`：
  - 取 `DateTimeOriginal`；缺失则回退 `CreateDate`、`ModifyDate`。
  - 解析日期为 `YYYY-MM-DD` 格式；无效时提示用户选择日期或使用文件创建时间（`URLResourceValues.contentCreationDate`）。

## 8. 输出与保存策略
- 输出目录：`source.parent + "_watermark"` 子目录（例如 `/photos/2024` → `/photos/2024_watermark`）。
- 文件命名：`basename + "_watermark" + ext`；存在冲突时追加 `(1)`, `(2)`…
- 输出格式：与输入一致；JPEG 可设质量（默认 0.9）。
- 元数据：尽量保留 EXIF；若系统 API 限制导致部分丢失，提供提示文案与开关。

## 9. 零依赖分发与合规
- 构建：Xcode 生成通用 `.app`（`arm64`+`x86_64`）。
- Zip 打包：`ditto -c -k --keepParent "PhotoWatermark.app" "PhotoWatermark.zip"` 保留资源与扩展属性。
- 无证书/未公证：
  - Finder 右键 `PhotoWatermark.app` → 打开 → 弹窗选择“打开”，一次性放行。
  - 或在终端执行：`xattr -dr com.apple.quarantine "/路径/PhotoWatermark.app"` 后直接双击运行。
- 可选签名与公证（若未来希望直接双击运行）：
  - `codesign --deep --force --options runtime --sign "Developer ID Application: Your Name (TEAMID)" "PhotoWatermark.app"`
  - `xcrun notarytool submit "PhotoWatermark.app" --keychain-profile <profile> --wait`
  - `xcrun stapler staple "PhotoWatermark.app"`

## 10. 性能与稳定性
- 预览保持比例缩放；使用原始像素进行导出绘制，避免质量损失。
- 对大图启用高效解码与一次性绘制；避免重复解码。
- 异常防护：权限、磁盘空间、路径无效、EXIF 异常均给出可读提示。

## 11. 开发里程碑
- v0.1：项目骨架（SwiftUI 窗口 + 文件打开 + 原图预览）。
- v0.2：EXIF 读取、`YYYY-MM-DD` 文本生成、预览水印叠加。
- v0.3：导出绘制与保存到子目录；基础错误处理；zip 打包与 README 放行指南。
- v0.4（可选）：通用构建、签名、公证，使用户可直接双击运行。
- v1.0：体验打磨、更多位置/边距设置、可选阴影/描边。

## 12. 目录结构（建议）
```
Photo-Watermark-Native/
├── PhotoWatermark.app/            # 构建产物
├── PhotoWatermark.xcodeproj       # Xcode 工程
├── PhotoWatermark/                # 源码
│   ├── App.swift                  # 入口
│   ├── ContentView.swift          # 主界面
│   ├── Services/
│   │   ├── ImageLoader.swift
│   │   ├── ExifReader.swift
│   │   ├── WatermarkLayout.swift
│   │   └── WatermarkRenderer.swift
│   └── Utils/
│       ├── OutputManager.swift
│       └── ErrorPresenter.swift
└── Resources/                     # 图标、本地化等
```

## 13. 风险与应对
- EXIF 字段不规范/缺失：提供替代策略与清晰提示。
- HEIC/RAW 变体：系统原生可读；RAW 视具体相机格式兼容性而定。
- 签名与公证流程复杂：建立 CI 脚本与文档，确保可重复执行。

## 14. 下一步
- 初始化 SwiftUI 工程（Xcode 项目）并提交骨架代码。
- 实现 v0.1–v0.3 的最小可用路径（打开 → 预览 → 解析 → 保存）。
- 配置通用构建、签名、公证与打包脚本，完成“下载即用”。