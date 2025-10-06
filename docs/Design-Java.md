# Photo Watermark macOS 应用：Java 设计说明（初版）

## 1. 技术栈与依赖
- 语言与运行时：Java 17（LTS）。
- GUI 框架：JavaFX 17+（现代UI、良好跨平台支持）。
- 元数据解析：`metadata-extractor`（读取 EXIF DateTimeOriginal 等）。
- 图像处理与保存：`ImageIO`（内置），建议配合 `TwelveMonkeys ImageIO` 增强格式支持；启用 `Graphics2D` 抗锯齿。
- 打包与分发：`jpackage` 生成 macOS 可执行包（.app/.dmg），后续可加签与图标。
- 项目构建：Gradle（推荐）或 Maven，首版选 Gradle。

## 2. 架构概览
- 分层：
  - UI 层（JavaFX）：视图与控制器，负责交互、预览与设置。
  - 领域层（Domain）：水印文本生成、布局与绘制算法。
  - 基础设施层（Infra）：EXIF 读取、文件系统、图片加载与保存。
- 设计原则：
  - 预览与导出共享同一布局与绘制逻辑，确保所见即所得。
  - 模块解耦（服务接口 + 实现），便于扩展和测试。

## 3. 核心模块与职责
- `App`（JavaFX Application）：应用入口，初始化主窗口与依赖。
- `MainController`：主界面控制器，管理文件打开、预览更新、保存动作。
- `SettingsPane`：右侧设置面板，包含字体大小、颜色、位置（左上/居中/右下）、边距。
- `PreviewPane`：预览区域，使用 `StackPane`：底层 `ImageView` 显示原图，上层叠加水印预览（`Canvas` 或 `Text`）。
- `ExifService`：解析图片的 EXIF 日期：优先 `DateTimeOriginal`，回退 `CreateDate`、`ModifyDate`。
- `WatermarkService`：
  - 文本生成：将时间转换为 `YYYY-MM-DD`。
  - 布局计算：根据位置枚举与边距计算文本锚点与绘制坐标。
  - 预览绘制：在 JavaFX 预览层叠加效果（不改原图）。
  - 导出绘制：对 `BufferedImage` 使用 `Graphics2D` 绘制水印文本。
- `ImageIOService`：图片加载/保存；保存时决定输出格式（与输入一致），JPEG 质量默认 90。
- `OutputPathService`：生成输出目录：`原目录名_watermark` 子目录；生成带 `_watermark` 的文件名，冲突时追加序号。
- `FallbackDateProvider`：当 EXIF 不可用时，提供两种替代：手动输入日期或使用文件创建时间（`Files.readAttributes`）。

## 4. 数据模型
- `WatermarkSettings`
  - `fontSize:int`（默认 24，范围 12–96）
  - `color:Color`（默认白色；可扩展透明度）
  - `position:WatermarkPosition`（`TOP_LEFT` / `CENTER` / `BOTTOM_RIGHT`）
  - `margin:int`（默认 16 px）
- `ImageContext`
  - `sourcePath:Path`（原文件路径）
  - `sourceImage:BufferedImage`（原图像素数据）
  - `captureDate:LocalDate`（拍摄日期或替代日期）

## 5. 界面与交互设计（JavaFX）
- 布局：`BorderPane`
  - Top：`MenuBar`（打开、保存、设置、帮助）
  - Center：`PreviewPane`（`StackPane{ ImageView, Overlay }`）
  - Right：`SettingsPane`（表单控件）
  - Bottom：`StatusBar`（解析状态、输出目录、错误提示）
- 流程：打开文件 → 解析 EXIF → 预览原图与水印 → 调整设置 → 保存。
- 异常：EXIF 不可用时弹窗提示并提供替代；保存失败显示具体原因。

## 6. 水印绘制与布局算法
- 字体度量：
  - 预览：JavaFX 使用 `Font` 与 `Text`/`Canvas` 计算文本宽高。
  - 导出：`Graphics2D` 使用 `FontMetrics` 计算文本边界。
- 坐标计算：
  - `TOP_LEFT`：`(margin, margin + metrics.ascent)`
  - `CENTER`：`((W - textW)/2, (H - textH)/2 + metrics.ascent)`
  - `BOTTOM_RIGHT`：`(W - textW - margin, H - textH - margin + metrics.ascent)`
- 渲染细节：
  - 启用抗锯齿：`RenderingHints.KEY_TEXT_ANTIALIASING`、`KEY_ANTIALIASING`。
  - 颜色与透明度：`Color` 转 `java.awt.Color`（如支持透明度则设置 `AlphaComposite`）。
- 一致性：预览与导出共用同一坐标计算逻辑，避免偏差。

## 7. EXIF 解析策略
- 使用 `metadata-extractor`：
  - `ExifSubIFDDirectory.TAG_DATETIME_ORIGINAL` → 优先。
  - 回退：`ExifSubIFDDirectory.TAG_DATETIME`、`ExifIFD0Directory.TAG_DATETIME`。
  - 解析到 `LocalDate`（忽略时分秒，仅保留年月日）。
- 无 EXIF：
  - 选择使用 `FallbackDateProvider`：手动输入或文件创建时间。

## 8. 文件输出与目录策略
- 输出目录：`sourceParent.resolve(sourceParentName + "_watermark")`。
- 文件名：`baseName + "_watermark" + ext`，若存在，追加 `(1)`, `(2)`...
- 格式处理：与输入一致；JPEG 写出质量 90（可配置）；PNG 无损。
- 元数据保留：基础保留；若受限，提供“尽量保留 EXIF”开关和提示说明。

## 9. 性能与稳定性
- 预览缩放：`ImageView.setPreserveRatio(true)`，降低内存压力。
- 大图处理：导出时基于原始分辨率绘制，避免预览分辨率影响输出质量。
- 异常防护：权限、空间不足、路径异常均有明确提示。

## 10. 构建与打包规划
- Gradle 配置：
  - 依赖：`org.openjfx:javafx-controls`, `com.drewnoakes:metadata-extractor`, `com.twelvemonkeys.imageio:imageio-jpeg/png`。
  - 任务：`run`（开发）、`jpackage`（macOS 应用打包）。
- 打包产物：`.app` 或 `.dmg`；后续可加入应用图标与代码签名。

## 11. 测试策略
- 单元测试：EXIF 解析（含缺失字段）、布局坐标计算。
- 集成测试：打开 → 预览 → 保存完整流程（以小样例图片）。
- 边界测试：超大图片、只读目录、文件名超长。

## 12. 未来扩展
- 批量处理与目录级处理。
- 九宫格更多位置、自定义偏移与透明度、描边/阴影增强可读性。
- 保留/编辑完整 EXIF 的高级选项。

## 13. 简要类与接口草图（示意）
- `class MainApp extends Application`
- `class MainController { openFile(), updatePreview(), save() }`
- `class WatermarkSettings { fontSize, color, position, margin }`
- `enum WatermarkPosition { TOP_LEFT, CENTER, BOTTOM_RIGHT }`
- `interface ExifService { Optional<LocalDate> readCaptureDate(Path path) }`
- `class MetadataExtractorExifService implements ExifService`
- `class WatermarkService { String toText(LocalDate), Point computePosition(...), BufferedImage applyWatermark(...) }`
- `class ImageIOService { BufferedImage load(Path), void save(BufferedImage, Path, String format, int quality) }`
- `class OutputPathService { Path resolveOutputDir(Path source), Path resolveOutputFile(Path source) }`
- `class FallbackDateProvider { LocalDate fromFileAttributes(Path); LocalDate fromManualInput() }`

## 14. 用户流程（文字序列图）
用户选择图片 → EXIF 解析日期 → 生成`YYYY-MM-DD`文本 → 设置样式与位置 → 预览实时更新 → 点击保存 → 创建`原目录名_watermark`子目录并写出新文件 → 状态栏提示成功与路径。