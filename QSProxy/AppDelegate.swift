//
//  AppDelegate.swift
//  QSProxy
//
//  Created by Drew on 2020/1/5.
//  Copyright © 2020 Drew. All rights reserved.
//

import Cocoa
import ServiceManagement

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    static let statusIcon = NSStatusBar.system.statusItem(withLength: NSApplication.shared.mainMenu!.menuBarHeight)
    static let proxyHost = "192.168.50.2"
    static let proxyPort = "1282"
    var proxyOn = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let launcherAppId = "cn.drewslab.qsproxylauncher"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty

        SMLoginItemSetEnabled(launcherAppId as CFString, true)

        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }
        
        // Insert code here to initialize your application
        AppDelegate.statusIcon.button?.image = NSImage(named: "icon_disconnected")
        AppDelegate.statusIcon.button?.image?.size = NSSize(width: NSApplication.shared.mainMenu!.menuBarHeight, height: NSApplication.shared.mainMenu!.menuBarHeight)
        
        if let button = AppDelegate.statusIcon.button {
            button.action = #selector(self.statusBarButtonClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        print("Launching")
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        print("Terminate")
    }

    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == NSEvent.EventType.rightMouseUp {
            print("Right click")
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "设置", action: #selector(self.settingClicked), keyEquivalent: "s"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: AppDelegate.statusIcon.button!.frame.height), in: AppDelegate.statusIcon.button)
        } else {
            if proxyOn {
                AppDelegate.statusIcon.button?.image = NSImage(named: "icon_disconnected")
                AppDelegate.statusIcon.button?.image?.size = NSSize(width: NSApplication.shared.mainMenu!.menuBarHeight, height: NSApplication.shared.mainMenu!.menuBarHeight)
                print(self.shell("networksetup -setwebproxystate \"wi-fi\" off"))
                print(self.shell("networksetup -setsecurewebproxystate \"wi-fi\" off"))
                print(self.shell("git config --global --unset http.proxy && git config --global --unset https.proxy"))
                proxyOn = false;
            } else {
                AppDelegate.statusIcon.button?.image = NSImage(named: "icon_connected")
                AppDelegate.statusIcon.button?.image?.size = NSSize(width: NSApplication.shared.mainMenu!.menuBarHeight, height: NSApplication.shared.mainMenu!.menuBarHeight)
                print(self.shell("networksetup -setwebproxy \"wi-fi\" " + AppDelegate.proxyHost + " " + AppDelegate.proxyPort))
                print(self.shell("networksetup -setsecurewebproxy \"wi-fi\" " + AppDelegate.proxyHost + " " + AppDelegate.proxyPort))
                print(self.shell("networksetup -setwebproxystate \"wi-fi\" on"))
                print(self.shell("networksetup -setsecurewebproxystate \"wi-fi\" on"))
                print(self.shell("git config --global http.proxy http://" + AppDelegate.proxyHost + ":" + AppDelegate.proxyPort + " && git config --global https.proxy http://" + AppDelegate.proxyHost + ":" + AppDelegate.proxyPort))
                proxyOn = true;
            }
            
        }
    }
    
    @objc func settingClicked() {
        print("settingClicked")
    }
    
    func shell(_ command: String) -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String

        return output
    }
}

