//
//  PeripheralViewController.swift
//  L2CapDemoMac
//
//  Created by Paul Wilkinson on 20/12/19.
//  Copyright © 2019 Paul Wilkinson. All rights reserved.
//

import Cocoa
import CoreBluetooth
import L2Cap

class PeripheralViewController: NSViewController {
    
    @IBOutlet weak var advertiseSwitch: NSSwitch!
    @IBOutlet weak var outputLabel: NSTextField!
    
    private var peripheral: L2CapPeripheral!
    private var connection: L2CapConnection?
    
    private var bytesReceived = 0 {
        didSet {
            DispatchQueue.main.async {
                self.outputLabel.stringValue = "Bytes received = \(self.bytesReceived)"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.peripheral = L2CapPeripheral(connectionHandler: { (connection) in
            self.connection = connection
            self.connection?.receiveCallback = { (connection, data) in
                DispatchQueue.main.async {
                    self.bytesReceived += data.count
                    if let str = String(data: data, encoding: .utf8) {
                        self.outputLabel.stringValue = str
                    }
                }
            }
        })
        self.bytesReceived = 0
    }
    
    @IBAction func advertiseSwitched(_ sender: NSSwitch) {
        self.peripheral.publish = sender.state == .on
    }
}
