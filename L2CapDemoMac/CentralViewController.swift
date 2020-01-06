//
//  ViewController.swift
//  L2CapDemoMac
//
//  Created by Paul Wilkinson on 20/12/19.
//  Copyright © 2019 Paul Wilkinson. All rights reserved.
//

import Cocoa
import CoreBluetooth
import L2Cap

class CentralViewController: NSViewController {
    
    @IBOutlet weak var scanSwitch: NSSwitch!
    @IBOutlet weak var inputText: NSTextField!
    @IBOutlet weak var byteLabel: NSTextField!
    @IBOutlet weak var sendButton: NSButton!
    
    private var peripheral: CBPeripheral?
    private var connection: L2CapConnection?
    private var characteristic: CBCharacteristic?
    
    private var l2capCentral: L2CapCentral!
    
    private var queueQueue = DispatchQueue(label: "queue queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    
    private var outputData = Data()
    
    
    private var bytesSent = 0 {
        didSet {
            self.byteLabel.stringValue = "Bytes sent = \(self.bytesSent)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.bytesSent = 0
        self.l2capCentral = L2CapCentral()
        self.l2capCentral.discoveredPeripheralCallback = { peripheral in
            self.peripheral = peripheral
            self.l2capCentral.connect(peripheral: peripheral) { connection in
                self.connection = connection
                self.connection?.receiveCallback = { (connection,data) in
                    print("Received data")
                }
                self.connection?.sentDataCallback = { (connection, count) in
                    self.bytesSent += count
                }
                DispatchQueue.main.async {
                    self.sendButton.isEnabled = true
                }
            }
        }
        self.l2capCentral.disconnectedPeripheralCallBack = { (connection, error) in
            print("Disconnected \(connection)")
            if let err = error {
                print("With error \(err)")
            }
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func scanSwitched(_ sender: NSSwitch) {
        self.l2capCentral.scan = sender.state == .on
    }
    
    @IBAction func sendTextTapped(_ sender: NSButton) {
        guard let connection = self.connection else {
            return
        }
        let text = self.inputText.stringValue
        if let data = text.data(using: .utf8) {
            connection.send(data: data)
        }
    }
    
    
}

