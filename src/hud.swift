// snag-hud <items.jsonl>: a click-through pill in the bottom-right corner that shows how many
// snags the open stack holds. It polls the file and exits once the stack is empty or finished.
import AppKit

let restingAlpha: CGFloat = 0.8

func snagCount(_ path: String) -> Int {
    guard let data = FileManager.default.contents(atPath: path) else { return 0 }
    return data.reduce(0) { $1 == UInt8(ascii: "\n") ? $0 + 1 : $0 }
}

@MainActor
final class Hud {
    let path: String
    let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
    let background = NSVisualEffectView()
    let label = NSTextField(labelWithString: "")
    var count = 0

    init(path: String) {
        self.path = path
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.appearance = NSAppearance(named: .darkAqua)
        window.alphaValue = restingAlpha

        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.addSubview(label)
        window.contentView = background
    }

    func tick() {
        let n = snagCount(path)
        if n == 0 { exit(0) }
        if n != count {
            let wasShown = count > 0
            count = n
            let text = NSMutableAttributedString(string: "● ", attributes: [.foregroundColor: NSColor.systemRed])
            text.append(NSAttributedString(string: "\(n) snag\(n == 1 ? "" : "s")", attributes: [.foregroundColor: NSColor.labelColor]))
            text.addAttribute(.font, value: NSFont.systemFont(ofSize: 12, weight: .medium), range: NSRange(location: 0, length: text.length))
            label.attributedStringValue = text
            if wasShown { pulse() }
        }
        place()
    }

    // Runs on every tick so the pill follows Dock and display changes without observers.
    func place() {
        guard let area = NSScreen.screens.first?.visibleFrame else { return }
        label.sizeToFit()
        let size = NSSize(width: ceil(label.frame.width) + 20, height: ceil(label.frame.height) + 8)
        let frame = NSRect(x: area.maxX - size.width - 16, y: area.minY + 16, width: size.width, height: size.height)
        guard frame != window.frame else { return }
        window.setFrame(frame, display: true)
        label.setFrameOrigin(NSPoint(x: 10, y: 4))
        background.maskImage = pill(height: size.height)
    }

    func pill(height: CGFloat) -> NSImage {
        let radius = height / 2
        let image = NSImage(size: NSSize(width: height, height: height), flipped: false) { rect in
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }

    func pulse() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            self.window.animator().alphaValue = 1
        }, completionHandler: {
            MainActor.assumeIsolated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    self.window.animator().alphaValue = restingAlpha
                }
            }
        })
    }
}

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: snag-hud <items.jsonl>\n".utf8))
    exit(2)
}

MainActor.assumeIsolated {
    NSApplication.shared.setActivationPolicy(.accessory)
    let hud = Hud(path: arguments[1])
    hud.tick()
    hud.window.orderFrontRegardless()
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
        MainActor.assumeIsolated { hud.tick() }
    }
    NSApp.run()
}
