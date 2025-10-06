import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Photo Watermark")
                .font(.largeTitle)
                .bold()

            Text("打开图片 → 解析 EXIF → 预览水印 → 保存")
                .foregroundStyle(.secondary)

            Text("后续将提供：打开、保存、预览设置面板等")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}