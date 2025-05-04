import Cocoa
import CoreServices

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayController: OverlayController!
    var monitor: Any?
    var keymapUpdater = KeymapUpdater()
    var holdHandler: HoldHandler?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Hide the app's main window from the Dock and prevent it from appearing
        NSApp.setActivationPolicy(.accessory) // Keeps the app running in the background
        holdHandler = HoldHandler(showHandler: {
            self.overlayController.updateKeys(self.keymapUpdater.updateKeys())
            self.overlayController.showOverlay()
        },
        hideHandler: {
            self.overlayController.hideOverlay()
        })

        // Initialize the overlay controller
        overlayController = OverlayController()

        // Initialize global key press monitoring (e.g., Option key press)
        monitorKeyPress()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func monitorKeyPress() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            holdHandler?.update(pressed: event.modifierFlags.contains(.option))
            
            if (event.keyCode == 123 || event.keyCode == 124) {
                holdHandler?.reset()
            }
        }
    }
}

class HoldHandler {
    var optionHoldDelay: TimeInterval = 0.5
    var isDown = false
    var workItem: DispatchWorkItem?
    
    var showHandler: (() -> Void)?
    var hideHandler: (() -> Void)?
    
    init(showHandler: ( () -> Void)? = nil, hideHandler: ( () -> Void)? = nil) {
        self.showHandler = showHandler
        self.hideHandler = hideHandler
    }
    
    func update(pressed: Bool) {
        if pressed && !isDown {
            isDown = true

            // Cancel any existing task
            workItem?.cancel()

            // Schedule a delayed task
            workItem = DispatchWorkItem {
                if self.isDown {
                    self.showHandler?()
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + optionHoldDelay, execute: workItem!)

        } else if !pressed && isDown {
            self.reset()
        }
    }
    
    func reset() {
        isDown = false

        // Cancel and hide
        workItem?.cancel()
        hideHandler?()
    }
}
