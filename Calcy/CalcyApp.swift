import SwiftUI
import SwiftData
import Cocoa
import HotKey

@main
struct CalcyApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var menu: NSMenu!
    private var aboutWindow: NSWindow?
    let openHotKey = HotKey(key: .v, modifiers: [.shift, .command])

    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        //Init the rootView along with the modelContainer containing the Calculation
        let rootView = CalculatorMainView().environment(\.managedObjectContext, PersistanceController.shared.container.viewContext)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "number.square.fill", accessibilityDescription: "Calcy")
            statusButton.action = #selector(handleClick(_:))
            statusButton.target = self
            statusButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        openHotKey.keyUpHandler = {
            self.togglePopover()
        }
        
        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: 400, height: 370)
        self.popover.behavior = .transient
        self.popover.contentViewController = NSHostingController(rootView: rootView)
        self.popover.contentViewController?.view.window?.makeKey()
        
        self.menu = NSMenu()

        menu.addItem(NSMenuItem(title: "About Calcy", action: #selector(openAboutScreen), keyEquivalent: "a"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Visit GitHub", action: #selector(openGitHub), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Visit our website", action: #selector(openCalcyWebsite), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    }

    @objc func handleClick(_ sender: NSButton) {
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp {
            // Handle right-click
            showOptionMenu(for: sender)
        } else {
            // Handle left-click
            togglePopover()
        }
    }
    
    // MARK: - Menu Actions
    @objc func openAboutScreen() {
        guard aboutWindow == nil else {
            aboutWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Initialize the aboutWindow here as before...
        aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 250, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        
        aboutWindow?.center()
        aboutWindow?.title = "About Calcy"
        //This line prevented the app from crashing when I closed the about view
        aboutWindow?.isReleasedWhenClosed = false

        // Create a vertical stack view to hold all components
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        // App Icon
        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 15 // Adjust the corner radius as needed
        imageView.layer?.masksToBounds = true

        if let image = NSImage(named: "AboutIcon") {
            imageView.image = image
            // Optionally, you might want to adjust the image scaling mode
            imageView.imageScaling = .scaleProportionallyUpOrDown
        }

        stackView.addArrangedSubview(imageView)

        // App Name
        let appNameLabel = NSTextField(labelWithString: "Calcy")
        appNameLabel.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        stackView.addArrangedSubview(appNameLabel)

        // Version
        let versionLabel = NSTextField(labelWithString: "Version 1.0.0")
        stackView.addArrangedSubview(versionLabel)

        // Copyright
        let copyrightLabel = NSTextField(labelWithString: "Copyright © 2024 ")
        stackView.addArrangedSubview(copyrightLabel)

        // Add stackView to the window's contentView
        if let contentView = aboutWindow?.contentView {
            contentView.addSubview(stackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                stackView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8)
            ])
        }

        // Show the window
        aboutWindow?.delegate = self
        
        // Show the window
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openGitHub() {
        if let url = URL(string: "https://github.com/Louf/calcy") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func openCalcyWebsite() {
        if let url = URL(string: "https://www.calcywebsite.com") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func showOptionMenu(for sender: NSButton) {
        // Ensure the menu is updated if needed, then display it
        let menuLocation = NSPoint(x: 0, y: sender.bounds.height)
        menu.popUp(positioning: nil, at: menuLocation, in: sender)
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                self.popover.performClose(nil)
            } else {
                // Show the popover
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                
                // After showing the popover, bring its window to the front and make it key
                if let popoverWindow = popover.contentViewController?.view.window {
                    popoverWindow.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true) // This line makes your app active and brings it to the foreground
                }
            }
        }
    }
    
}
