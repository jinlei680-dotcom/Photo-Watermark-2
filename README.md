# Photo-Watermark-2

一个原生 macOS 图片水印工具（SwiftUI + AppKit）。

支持：读取 EXIF 拍摄日期、实时预览、导出保存到 `*_watermark` 子目录；文字/图片水印二选一，提供字体、颜色、位置、边距等设置。第三版引入“水印模板”与导出参数持久化，显著提升连贯体验。

## 下载与运行（v3）
- 前往 GitHub Releases 下载 `PhotoWatermark-v3.0.x-macos.dmg`（最新第三版）。
- 双击打开 DMG（磁盘映像），将 `PhotoWatermark.app` 拖入 `Applications`，或直接在 DMG 中打开。
- 首次运行（未签名/未公证，一次性放行）：
  - 方法A：在 Finder 右键 `PhotoWatermark.app` → 选择“打开” → 弹窗中再次点击“打开”。
  - 方法B：系统设置 → 隐私与安全性 → 允许打开来自未识别开发者的应用。
  - 方法C（命令行，可选）：`xattr -dr com.apple.quarantine "/Applications/PhotoWatermark.app"` 去除隔离标记。

说明：
- 由于 Gatekeeper 的隔离属性，互联网下载的应用首次需要一次性放行。
- 此版本未签名/未公证，按上面的“首次运行指南”即可正常使用；未来可提供签名与公证版以支持直接双击运行。

## v3.0.x 亮点
- 新增“水印模板功能”：启动时自动恢复上次会话的水印设置（隐式模板），减少重复配置。
- 参数持久化范围扩展：边距、导出格式、命名规则、前/后缀、JPEG质量、尺寸模式与数值、导出目录路径等均可恢复。
- UI 映射函数完善：统一 `makeDTOFromUI` / `applyDTOToUI`，确保预览与导出一致（所见即所得）。
- 新增 `margin（边距）` 控制，并在 UI 与导出中统一生效。
- 分发优化：新增未签名 DMG 构建与发布，下载后无需解压；Release 附带“首次运行指南”。

## 使用步骤
1. 打开图片（支持拖放或选择文件）。
2. 自动解析 EXIF 拍摄日期，生成 `YYYY-MM-DD` 文本（无则提供替代策略）。
3. 配置水印：
   - 文字：字体大小/族、颜色、不透明度、位置、边距；可选阴影/描边。
   - 图片：选择图片、百分比缩放或指定尺寸、不透明度；位置与边距与文字一致。
4. 模板与持久化：第三版会自动恢复上次的设置（隐式模板），你也可按需调整。
5. 预览实时更新。
6. 点击“保存”，在原目录下生成 `原目录名_watermark` 子目录，文件名追加 `_watermark`。

## 常见问题
- 无 EXIF 日期：支持手动选择日期或使用文件创建时间。
- 运行被拒绝：对 `.app` 执行一次性放行（见“下载与运行”章节）。
- 输出格式：与输入一致（JPEG 默认质量 90；PNG 无损）。
- DMG 使用：打开后可直接运行或拖到 `Applications`，两种方式均可。

## 开发与发布
- 使用 SwiftPM 构建：`swift build -c release`。
- CI（GitHub Actions）在推送 `v*` 标签时自动：
  - 构建 Release 二进制与最小 `.app` 包，并打包为未签名 DMG：`dist/PhotoWatermark-<tag>-macos.dmg`；
  - 创建 Release 并附带 DMG 与详细变更说明。

## 许可证
MIT License（见 `LICENSE`）。
