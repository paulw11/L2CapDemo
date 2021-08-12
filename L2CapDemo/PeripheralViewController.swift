//
//  SecondViewController.swift
//  L2CapDemo
//
//  Created by Paul Wilkinson on 17/1/19.
//  Copyright © 2019 Paul Wilkinson. All rights reserved.
//

import UIKit
import CoreBluetooth
import L2Cap

class PeripheralViewController: UIViewController {
    
    @IBOutlet weak var advertiseSwitch: UISwitch!
    @IBOutlet weak var publishSwitch: UISwitch!
    @IBOutlet weak var outputLabel: UILabel!
    
    private var peripheral: L2CapPeripheral!
    private var connection: L2CapConnection?
    
    private var bytesReceived = 0 {
        didSet {
            DispatchQueue.main.async {
                self.outputLabel.text = "Bytes received = \(self.bytesReceived)"
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
                        self.outputLabel.text = str
                    }
                }
            }
        })
        self.bytesReceived = 0
    }
    
    @IBAction func advertiseSwitched(_ sender: UISwitch) {
      self.peripheral.publish = sender.isOn
        self.publishSwitch.isOn = sender.isOn
    }
    
    @IBAction func publishSwitched(_ sender: UISwitch) {
        self.peripheral.publishChannel = sender.isOn
    }
}
