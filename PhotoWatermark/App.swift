import SwiftUI

@main
struct PhotoWatermarkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            if let win = NSApp.windows.first {
                win.makeKeyAndOrderFront(nil)
            } else {
                // 回退：显式创建一个窗口承载 ContentView
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable],
                    backing: .buffered,
                    defer: false
                )
                window.center()
                window.title = "PhotoWatermark"
                window.contentView = NSHostingView(rootView: ContentView())
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}