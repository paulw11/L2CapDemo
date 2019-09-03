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

class CentralViewController: UIViewController {
    
    @IBOutlet weak var scanSwitch: UISwitch!
    @IBOutlet weak var inputText: UITextField!
    @IBOutlet weak var byteLabel: UILabel!
    
    private var peripheral: CBPeripheral?
    private var channel: CBL2CAPChannel?
    private var characteristic: CBCharacteristic?
    
    private var bytesSent = 0 {
        didSet {
            self.byteLabel.text = "Bytes sent = \(self.bytesSent)"
        }
    }
    
    private var queueQueue = DispatchQueue(label: "queue queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    
    private var outputData = Data()
    
    var central:CBCentralManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.central = CBCentralManager(delegate: self, queue: nil)
        self.bytesSent = 0
    }
    
    @IBAction func scanSwitched(_ sender: UISwitch) {
        sender.isOn ? startScan():stopScan()
    }
    
    @IBAction func sendTextTapped(_ sender: UIButton) {
        var lngStr = "1234567890"
        for _ in 1...10 {lngStr = lngStr + lngStr}
        for _ in 1...10 {
        let data = lngStr.data(using: .utf8)!
        self.queue(data:data)
        }
    }
    
    private func queue(data: Data) {
        queueQueue.sync  {
            self.outputData.append(data)
        }
        self.send()
    }
    
    private func send() {
        
        guard let ostream = self.channel?.outputStream, !self.outputData.isEmpty, ostream.hasSpaceAvailable  else{
            return
        }
        let bytesWritten =  outputData.withUnsafeBytes { ostream.write($0, maxLength: self.outputData.count) }
        print("bytesWritten = \(bytesWritten)")
        self.bytesSent+=bytesWritten
        queueQueue.sync {
            if bytesWritten < outputData.count {
                outputData = outputData.advanced(by: bytesWritten)
            } else {
                outputData.removeAll()
            }
        }
    }
    
    func startScan() {
        self.central.scanForPeripherals(withServices: [Constants.serviceID], options: nil)
    }
    
    func stopScan() {
        self.scanSwitch.isOn = false
        self.central.stopScan()
    }
}

extension CentralViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let poweredOn = central.state == .poweredOn
        self.scanSwitch.isEnabled = poweredOn
        self.inputText.isEnabled = poweredOn
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        peripheral.delegate = self
        print("Discovered \(peripheral)")
        self.central.connect(peripheral, options: nil)
        self.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([Constants.serviceID])
    }
    
}

extension CentralViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Service discovery error - \(error)")
            return
        }
        
        
        
        for service in peripheral.services ?? [] {
            print("Discovered service \(service)")
            if service.uuid == Constants.serviceID {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Characteristic discovery error - \(error)")
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            print("Discovered characteristic \(characteristic)")
            if characteristic.uuid ==  Constants.PSMID {
                self.characteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Characteristic update error - \(error)")
            return
        }
        
        print("Read characteristic \(characteristic)")
        
        if let dataValue = characteristic.value, let string = String(data: dataValue, encoding: .utf8), let psm = UInt16(string) {
                print("Opening channel \(psm)")
                self.peripheral?.openL2CAPChannel(psm)
        } else {
            print("Problem decoding PSM")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        if let error = error {
            print("Error opening l2cap channel - \(error.localizedDescription)")
            return
        }
        guard let channel = channel else {
            return
        }
        print("Opened channel \(channel)")
        self.channel = channel
        channel.inputStream.delegate = self
        channel.outputStream.delegate = self
        print("Opened channel \(channel)")
        channel.inputStream.schedule(in: RunLoop.current, forMode: .default)
        channel.outputStream.schedule(in: RunLoop.current, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.open()
    }
    

}

extension CentralViewController: StreamDelegate {
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            print("Stream is open")
        case Stream.Event.endEncountered:
            print("End Encountered")
        case Stream.Event.hasBytesAvailable:
            print("Bytes are available")
        case Stream.Event.hasSpaceAvailable:
            print("Space is available")
            self.send()
        case Stream.Event.errorOccurred:
            print("Stream error")
        default:
            print("Unknown stream event")
        }
    }
}
