import Cocoa

class OverlayWindow: NSWindow {
    init(content: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .transient]
        self.contentView = content
        self.isReleasedWhenClosed = false
    }
}

class OverlayController {
    private var overlayWindow: OverlayWindow!
    private var stackView: NSStackView!

    init() {
        setupOverlay()
    }

    private func setupOverlay() {
        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        contentView.layer?.cornerRadius = 12

        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 6
        stackView.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        overlayWindow = OverlayWindow(content: contentView)
    }

    func updateKeys(_ keyMap: [String: String]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (key, command) in keyMap.sorted(by: { $0.key < $1.key }) {
            let label = NSTextField(labelWithString: "⌥ \(key): \(command)")
            label.textColor = .white
            label.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
            stackView.addArrangedSubview(label)
        }

        stackView.layoutSubtreeIfNeeded()

        let contentSize = stackView.fittingSize
        overlayWindow.setContentSize(contentSize)

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = overlayWindow.frame.size
            let origin = NSPoint(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.midY - windowSize.height / 2
            )
            overlayWindow.setFrameOrigin(origin)
        }
    }

    func showOverlay() {
        overlayWindow.orderFront(nil)
    }

    func hideOverlay() {
        overlayWindow.orderOut(nil)
    }
}
