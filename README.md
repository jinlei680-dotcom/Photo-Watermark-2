# Photo-Watermark-2

一个原生 macOS 图片水印工具（SwiftUI + AppKit）。

支持：读取 EXIF 拍摄日期、实时预览、导出保存到 `*_watermark` 子目录；文字/图片水印二选一，提供字体、颜色、位置、边距等设置。

## 下载与运行
- 前往 GitHub Releases 下载 `PhotoWatermark-v2.0.0-macos.zip`（或对应版本）。
- 解压得到可执行文件 `PhotoWatermark`（或 CI 生成的 `dist/PhotoWatermark-*.zip` 中的同名二进制）。
- 首次运行（未签名/未公证，一次性放行）：
  - 方法A：在 Finder 右键 `PhotoWatermark` → 选择“打开” → 弹窗中再次点击“打开”。
  - 方法B（命令行）：
    - `xattr -dr com.apple.quarantine "/路径/PhotoWatermark"`
    - `chmod +x "/路径/PhotoWatermark" && "/路径/PhotoWatermark"`

说明：
- 由于 Gatekeeper 的隔离属性，互联网下载的应用首次需要一次性放行。
- 后续将提供签名与公证版本，以便直接双击运行。

## v2.0.0 亮点
- 引入“水印类型”分段选择（文字 / 图片），两者互斥，避免同时启用造成混乱。
- 将水印类型选择移动至操作区更显著位置，交互更清晰。
- 图片水印缩放支持百分比模式（0.01%–100%），边界更健壮；默认 50%。
- 阴影与描边设置仅在“文字水印”类型下显示，阴影参数拆分为两行（偏移 X/Y；半径/颜色/透明度）。
- 统一以 `watermarkType` 控制渲染与保存逻辑，预览与导出一致（所见即所得）。

## 使用步骤
1. 打开图片（支持拖放或选择文件）。
2. 自动解析 EXIF 拍摄日期，生成 `YYYY-MM-DD` 文本（无则提供替代策略）。
3. 在右侧面板选择水印类型（文字 / 图片）并配置样式：
   - 文字：字体大小/族、颜色、不透明度、位置、边距；可选阴影/描边。
   - 图片：选择图片、百分比缩放或指定尺寸、不透明度；位置与边距与文字一致。
4. 预览实时更新。
5. 点击“保存”，在原目录下生成 `原目录名_watermark` 子目录，文件名追加 `_watermark`。

## 常见问题
- 无 EXIF 日期：支持手动选择日期或使用文件创建时间。
- 运行被拒绝：对下载的二进制执行一次性放行（见上文）。
- 输出格式：与输入一致（JPEG 默认质量 90；PNG 无损）。

## 开发与发布
- 使用 SwiftPM 构建：`swift build -c release`。
- CI（GitHub Actions）在推送 `v*` 标签时自动：
  - 构建 Release 二进制并打包为 `dist/PhotoWatermark-<tag>-macos.zip`；
  - 上传本地版本号匹配的 zip（如仓库根目录下 `PhotoWatermark-<tag>-macos.zip`）；
  - 创建 Release 并附带上述构建包与变更说明。

## 许可证
MIT License（见 `LICENSE`）。
