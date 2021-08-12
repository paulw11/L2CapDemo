//
//  FirstViewController.swift
//  L2CapDemo
//
//  Created by Paul Wilkinson on 17/1/19.
//  Copyright © 2019 Paul Wilkinson. All rights reserved.
//

import UIKit
import CoreBluetooth
import ExternalAccessory
import L2Cap

class CentralViewController: UIViewController {
    
    @IBOutlet weak var scanSwitch: UISwitch!
    @IBOutlet weak var inputText: UITextField!
    @IBOutlet weak var byteLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var stateLabel: UILabel!
    
    private var peripheral: CBPeripheral?
    private var connection: L2CapConnection?
    private var characteristic: CBCharacteristic?
    
    private var l2capCentral: L2CapCentral!
    
    private var bytesSent = 0 {
        didSet {
            self.byteLabel.text = "Bytes sent = \(self.bytesSent)"
        }
    }
    
    private var queueQueue = DispatchQueue(label: "queue queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    
    private var outputData = Data()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.bytesSent = 0
        self.l2capCentral = L2CapCentral()
        self.l2capCentral.discoveredPeripheralCallback = { peripheral in
            print("Discovered peripheral \(peripheral)")
            self.peripheral = peripheral
            self.connect(peripheral: peripheral)
        }
        
        self.l2capCentral.disconnectedPeripheralCallBack = { (connection,error) in
            print("\(connection) disconnected")
            if let error = error {
                print("\(error)")
            }
            self.connection = nil
            if let peripheral = self.peripheral {
                print("Reconnecting to \(peripheral)...")
                self.connect(peripheral: peripheral)
            }
        }
    }
    
    private func connect(peripheral: CBPeripheral) {
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
            self.connection?.stateChangeCallback = { (connection, eventCode) in
                switch eventCode {
                case Stream.Event.openCompleted:
                    self.stateLabel.text = "Stream is open"
                case Stream.Event.endEncountered:
                    self.stateLabel.text = "End encountered"
                    self.connection?.close()
                    self.connection = nil
                    break
                case Stream.Event.hasBytesAvailable:
                    break
                case Stream.Event.hasSpaceAvailable:
                    break
                case Stream.Event.errorOccurred:
                    self.stateLabel.text = "Stream error"
                    self.connection?.close()
                    self.connection = nil
                default:
                    self.stateLabel.text = "Unknown stream event"
                }
            }
        }
    }
    
    @IBAction func scanSwitched(_ sender: UISwitch) {
         self.l2capCentral.scan = sender.isOn
    }
    
    @IBAction func sendTextTapped(_ sender: UIButton) {
        guard let connection = self.connection else {
            return
        }
        if let text = self.inputText.text, let data = text.data(using: .utf8) {
            connection.send(data: data)
        }
    }
}
    
