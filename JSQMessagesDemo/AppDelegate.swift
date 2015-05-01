//
//  AppDelegate.swift
//  RabbitMQSwift
//
//  Created by Carl Gleisner on 2014-10-26.
//  Copyright (c) 2014 Carl Gleisner. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBAction func pushButton(sender: AnyObject) {
        var connection = AMQPConnection()
        connection.connectToHost("localhost", port: 5672)
        connection.loginAsUser("guest", password: "guest")
        sleep(5)
    }

}

