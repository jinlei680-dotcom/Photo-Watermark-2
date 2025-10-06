# Photo-Watermark-2

一个原生 macOS 图片水印工具（SwiftUI + AppKit）。

运行方式（未签名/未公证，一次性放行）：
- 从仓库下载 `PhotoWatermark.zip` 并解压。
- 方式A（推荐）：在 Finder 右键 `PhotoWatermark.app` → 选择“打开” → 弹窗中再次点击“打开”。
- 方式B（命令行）：在终端执行
  - `xattr -dr com.apple.quarantine "/路径/PhotoWatermark.app"`
  然后双击运行或执行 `open "/路径/PhotoWatermark.app"`。

说明：
- 由于 Gatekeeper 的隔离属性，互联网下载的应用首次需要一次性放行。
- 如后续需要“直接双击运行”，将提供签名与公证版本。

功能规划：
- 打开图片、读取 EXIF 拍摄日期、预览水印、保存到 `*_watermark` 子目录。
- 更多位置/样式、批量处理与模板将逐步加入。
