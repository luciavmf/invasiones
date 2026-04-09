//
//  AppDelegate.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 03.04.26.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let viewController = ViewController()

        let contentRect = NSRect(x: 0, y: 0, width: ScreenSize.width, height: ScreenSize.height)
        window = NSWindow(
            contentRect: contentRect,
            styleMask:   [.titled, .closable, .miniaturizable, .resizable],
            backing:     .buffered,
            defer:       false
        )
        window.title = "Invasiones"
        window.contentViewController = viewController
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
