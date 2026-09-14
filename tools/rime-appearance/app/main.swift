// 鼠鬚管外觀編輯器 —— macOS 外殼。
//
// 啟動隨附的 server.py，讀出它印出的網址，用 WKWebView 載入。
// 使用者看到的是一般的 app 視窗，沒有瀏覽器。

import AppKit
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    private var window: NSWindow!
    private var webView: WKWebView!
    private var server: Process?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
        startServer()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        // server.py 是子程序，app 結束時一併收掉，不要留在背景
        server?.terminate()
    }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1160, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "鼠鬚管外觀編輯器"
        window.setFrameAutosaveName("RimeAppearanceMain")
        window.minSize = NSSize(width: 760, height: 560)

        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        window.contentView!.addSubview(webView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        showMessage("正在啟動…")
    }

    private func showMessage(_ text: String) {
        let escaped = text.replacingOccurrences(of: "<", with: "&lt;")
        webView.loadHTMLString("""
        <meta charset="utf-8"><meta name="color-scheme" content="light dark">
        <div style="font:14px -apple-system,'PingFang TC',sans-serif;
             display:flex;height:100vh;align-items:center;justify-content:center;
             color:#888;text-align:center;padding:0 32px;line-height:1.7">\(escaped)</div>
        """, baseURL: nil)
    }

    /// 依序找可用的 python3。系統內建的 /usr/bin/python3 一定在，放最後當保底。
    private func findPython() -> String? {
        let candidates = ["/opt/homebrew/bin/python3", "/usr/local/bin/python3", "/usr/bin/python3"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func startServer() {
        guard let script = Bundle.main.path(forResource: "server", ofType: "py") else {
            showMessage("找不到 server.py，這個 app 的內容不完整。")
            return
        }
        guard let python = findPython() else {
            showMessage("找不到 python3。請先安裝 Xcode 命令列工具：<br><br>xcode-select --install")
            return
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: python)
        task.arguments = ["-u", script, "--no-browser"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
        } catch {
            showMessage("無法啟動 server.py：\(error.localizedDescription)")
            return
        }
        server = task

        // 逐行讀 stdout，等它印出網址。首次啟動要掃系統字型，可能要十幾秒。
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var buffer = Data()
            let handle = pipe.fileHandleForReading
            while true {
                let chunk = handle.availableData
                if chunk.isEmpty { break }
                buffer.append(chunk)
                guard let text = String(data: buffer, encoding: .utf8) else { continue }
                if text.contains("正在讀取系統字型") {
                    DispatchQueue.main.async {
                        self?.showMessage("首次啟動，正在讀取系統字型…<br>約需 15 秒，之後會記住。")
                    }
                }
                if let range = text.range(of: #"http://127\.0\.0\.1:\d+/"#, options: .regularExpression) {
                    let url = String(text[range])
                    DispatchQueue.main.async { self?.load(url) }
                    return
                }
            }
            DispatchQueue.main.async {
                self?.showMessage("server.py 沒有回報網址就結束了。<br>請在終端機直接執行它看錯誤訊息。")
            }
        }
    }

    private func load(_ url: String) {
        guard let u = URL(string: url) else { return }
        webView.load(URLRequest(url: u))
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)

// 最小可用的選單列：沒有這個，⌘Q、⌘W、剪下貼上都不會動
let mainMenu = NSMenu()
let appItem = NSMenuItem()
mainMenu.addItem(appItem)
let appMenu = NSMenu()
appMenu.addItem(withTitle: "關於鼠鬚管外觀編輯器", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
appMenu.addItem(.separator())
appMenu.addItem(withTitle: "隱藏", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
appMenu.addItem(withTitle: "結束", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
appItem.submenu = appMenu

let editItem = NSMenuItem()
mainMenu.addItem(editItem)
let editMenu = NSMenu(title: "編輯")
for (title, selector, key) in [
    ("復原", Selector(("undo:")), "z"), ("重做", Selector(("redo:")), "Z"),
    ("剪下", #selector(NSText.cut(_:)), "x"), ("拷貝", #selector(NSText.copy(_:)), "c"),
    ("貼上", #selector(NSText.paste(_:)), "v"), ("全選", #selector(NSText.selectAll(_:)), "a"),
] {
    editMenu.addItem(withTitle: title, action: selector, keyEquivalent: key)
}
editItem.submenu = editMenu
app.mainMenu = mainMenu

app.run()
