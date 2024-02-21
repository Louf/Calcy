//
//  CalcyApp.swift
//  Calcy
//
//  Created by Louis Farmer on 2/16/24.
//

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
//        .modelContainer(modelContainer)

    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let openHotKey = HotKey(key: .v, modifiers: [.shift, .command])

    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        //Init the rootView along with the modelContainer containing the Calculation
        let rootView = CalculatorMainView().environment(\.managedObjectContext, PersistanceController.shared.container.viewContext)

        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "number.square.fill", accessibilityDescription: "Calcy")
            statusButton.action = #selector(togglePopover)
        }
        
        openHotKey.keyUpHandler = {
            self.togglePopover()
        }
        
        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: 400, height: 370)
        self.popover.behavior = .transient
        self.popover.contentViewController = NSHostingController(rootView: rootView)
        self.popover.contentViewController?.view.window?.makeKey()
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

