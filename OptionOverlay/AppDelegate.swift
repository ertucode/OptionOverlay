import Cocoa
import CoreServices

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayController: OverlayController!
    var monitor: Any?
    var holdHandler: HoldHandler?
    var configLoader = ConfigLoader()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Hide the app's main window from the Dock and prevent it from appearing
        NSApp.setActivationPolicy(.accessory) // Keeps the app running in the background
        holdHandler = HoldHandler(showHandler: {
            self.configLoader.loadConfig {result in
                let dict = switch result {
                case .success(let config):
                    ConfigParser.parse(config: config)
                case .failure(let error):
                    ["error": error.localizedDescription]
                }
                self.overlayController.updateKeys(dict)
                self.overlayController.showOverlay()
            }
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
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self else { return }
            
            switch event.type {
                case .keyDown:
                    if (event.keyCode == 0x7C || event.keyCode == 0x7B) {
                        holdHandler?.reset()
                    }
                    break
                    
                case .flagsChanged:
                    holdHandler?.update(pressed: event.modifierFlags.contains(.option))
                    break
                    
                default:
                    break
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
