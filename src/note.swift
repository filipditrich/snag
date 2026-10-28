// snag-note <png>: shows the screenshot with a note field.
// Add (⌘↵) prints the note to stdout and exits 0. Discard (esc) or closing exits 1.
import AppKit

final class NotePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class NoteController: NSObject, NSWindowDelegate, NSTextViewDelegate {
    let panel: NotePanel
    let textView: NSTextView
    let placeholder = NSTextField(labelWithString: "What's wrong?")

    init(image: NSImage) {
        let maxSize = NSSize(width: 560, height: 360)
        let scale = min(1, maxSize.width / image.size.width, maxSize.height / image.size.height)
        let imageSize = NSSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let inset: CGFloat = 16
        let contentWidth = max(imageSize.width, 380)

        let scroll = NSTextView.scrollableTextView()
        textView = scroll.documentView as! NSTextView

        panel = NotePanel(
            contentRect: .zero,
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.delegate = self
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            panel.standardWindowButton(button)?.isHidden = true
        }

        let background = NSVisualEffectView()
        background.material = .popover
        background.blendingMode = .behindWindow
        background.state = .active
        panel.contentView = background

        let imageView = NSImageView(image: image)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 8
        imageView.layer?.masksToBounds = true
        imageView.layer?.borderWidth = 1
        imageView.layer?.borderColor = NSColor.separatorColor.cgColor

        textView.font = .systemFont(ofSize: 14)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.delegate = self
        scroll.borderType = .noBorder
        scroll.wantsLayer = true
        scroll.layer?.cornerRadius = 8
        scroll.layer?.borderWidth = 1
        scroll.layer?.borderColor = NSColor.separatorColor.cgColor

        placeholder.font = textView.font
        placeholder.textColor = .placeholderTextColor
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholder)
        let padding = textView.textContainer?.lineFragmentPadding ?? 5

        let hint = NSTextField(labelWithString: "⌘↵ add  ·  esc discard")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .tertiaryLabelColor

        let discard = NSButton(title: "Discard", target: self, action: #selector(discardNote))
        let add = NSButton(title: "Add", target: self, action: #selector(addNote))
        add.bezelColor = .controlAccentColor
        add.keyEquivalent = "\r"
        add.keyEquivalentModifierMask = .command
        for button in [discard, add] { button.controlSize = .large }

        let buttons = NSStackView(views: [hint, NSView(), discard, add])
        buttons.orientation = .horizontal
        buttons.spacing = 8

        let stack = NSStackView(views: [imageView, scroll, buttons])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: inset + 12, left: inset, bottom: inset, right: inset)
        stack.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            stack.topAnchor.constraint(equalTo: background.topAnchor),
            stack.bottomAnchor.constraint(equalTo: background.bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: imageSize.width),
            imageView.heightAnchor.constraint(equalToConstant: imageSize.height),
            scroll.widthAnchor.constraint(equalToConstant: contentWidth),
            scroll.heightAnchor.constraint(equalToConstant: 96),
            buttons.widthAnchor.constraint(equalToConstant: contentWidth),
            placeholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: textView.textContainerInset.width + padding),
            placeholder.topAnchor.constraint(equalTo: textView.topAnchor, constant: textView.textContainerInset.height),
        ])

        panel.setContentSize(background.fittingSize)
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        if let area = screen?.visibleFrame {
            let size = panel.frame.size
            panel.setFrameOrigin(NSPoint(x: area.midX - size.width / 2, y: area.midY - size.height / 2))
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isReturn = event.keyCode == 36 || event.keyCode == 76
            if isReturn && mods == .command {
                self?.addNote()
            } else if event.keyCode == 53 && mods.isEmpty {
                self?.discardNote()
            }
            return event
        }
    }

    func show() {
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(textView)
    }

    @objc func addNote() {
        FileHandle.standardOutput.write(Data(textView.string.utf8))
        exit(0)
    }

    @objc func discardNote() {
        exit(1)
    }

    func windowWillClose(_ notification: Notification) {
        exit(1)
    }

    func textDidChange(_ notification: Notification) {
        placeholder.isHidden = !textView.string.isEmpty
    }
}

let arguments = CommandLine.arguments
guard arguments.count == 2, let image = NSImage(contentsOfFile: arguments[1]) else {
    FileHandle.standardError.write(Data("usage: snag-note <png>\n".utf8))
    exit(2)
}

MainActor.assumeIsolated {
    NSApplication.shared.setActivationPolicy(.accessory)
    let controller = NoteController(image: image)
    controller.show()
    NSApp.run()
}
