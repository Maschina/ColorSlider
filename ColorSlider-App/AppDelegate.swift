//
//  AppDelegate.swift
//  ColorSlider-App
//
//  Created by Robert Hahn on 23.05.19.
//  Copyright © 2019 Robert Hahn. All rights reserved.
//

import Cocoa
import ColorSlider

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var colorSlider: ColorSlider!
    @IBOutlet weak var colorLabel: NSTextField!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        colorSlider.isContinuous = false
        colorSlider.action = #selector(onChangeColorSlider)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func onClickSaturation(_ sender: NSSlider) {
        colorSlider.saturation = sender.floatValue
    }
    
    @objc func onChangeColorSlider(_ sender: ColorSlider) {
        colorLabel.stringValue = String(sender.floatValue)
    }
}
