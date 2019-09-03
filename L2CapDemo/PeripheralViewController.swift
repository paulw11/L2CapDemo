//
//  SecondViewController.swift
//  L2CapDemo
//
//  Created by Paul Wilkinson on 17/1/19.
//  Copyright © 2019 Paul Wilkinson. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralViewController: UIViewController {
    
    @IBOutlet weak var advertiseSwitch: UISwitch!
    @IBOutlet weak var outputLabel: UILabel!
    
    private var service: CBMutableService!
    private var characteristic: CBMutableCharacteristic!
    private var channel: CBL2CAPChannel?
    private var channelPSM: UInt16?
    
    var peripheralManager: CBPeripheralManager!
    var subscribedCentrals = [CBCharacteristic:[CBCentral]]()
    
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
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        self.bytesReceived = 0
    }
    
    @IBAction func advertiseSwitched(_ sender: UISwitch) {
        sender.isOn ? startAdvertise():stopAdvertise()
    }
    
    func startAdvertise() {
        self.service = CBMutableService(type: Constants.serviceID, primary: true)
        self.characteristic = CBMutableCharacteristic(type: Constants.PSMID, properties: [ CBCharacteristicProperties.read, CBCharacteristicProperties.indicate], value: nil, permissions: [CBAttributePermissions.readable] )
        self.service.characteristics = [self.characteristic]
        self.peripheralManager.add(self.service)
        self.peripheralManager.publishL2CAPChannel(withEncryption: false)
        self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [Constants.serviceID]])
    }
    
    func stopAdvertise() {
        self.advertiseSwitch.isOn = false
        self.peripheralManager.stopAdvertising()
    }

}


extension PeripheralViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        let poweredOn = peripheral.state == .poweredOn
        self.advertiseSwitch.isEnabled = poweredOn
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        var centrals = self.subscribedCentrals[characteristic, default: [CBCentral]()]
        centrals.append(central)
        self.subscribedCentrals[characteristic]  = centrals
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        if let error = error {
            print("Error publishing channel: \(error.localizedDescription)")
            return
        }
        print("Published channel \(PSM)")
        
        self.channelPSM = PSM
        
        if let data = "\(PSM)".data(using: .utf8) {
            
            self.characteristic.value = data
            
            self.peripheralManager.updateValue(data, for: self.characteristic, onSubscribedCentrals: self.subscribedCentrals[self.characteristic])
        }
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if let psm = self.channelPSM, let data = "\(psm)".data(using: .utf8) {
            request.value = characteristic.value
             print("Respond \(data)")
            self.peripheralManager.respond(to: request, withResult: .success)
        } else {
            self.peripheralManager.respond(to: request, withResult: .unlikelyError)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        if let error = error {
            print("Error opening channel: \(error.localizedDescription)")
            return
        }
        self.channel = channel
        if let channel = self.channel {
            print("Opened channel \(channel)")
            channel.inputStream.delegate = self
            channel.outputStream.delegate = self
            channel.inputStream.schedule(in: RunLoop.current, forMode: .common)
            channel.outputStream.schedule(in: RunLoop.current, forMode: .common)
            channel.inputStream.open()
            channel.outputStream.open()
        }
    }
    
    func readBytes() {
        if let iStream = channel?.inputStream {
            let bufLength = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufLength)
            let bytesRead = iStream.read(buffer, maxLength: bufLength)
            print("bytesRead = \(bytesRead)")
            self.bytesReceived += bytesRead
            if iStream.hasBytesAvailable {
                self.readBytes()
            }
        }
    }
    
}

extension PeripheralViewController: StreamDelegate {
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            print("Stream is open")
        case Stream.Event.endEncountered:
            print("End Encountered")
        case Stream.Event.hasBytesAvailable:
            print("Bytes are available")
            self.readBytes()
        case Stream.Event.hasSpaceAvailable:
            print("Space is available")
        case Stream.Event.errorOccurred:
            print("Stream error")
        default:
            print("Unknown stream event")
        }
    }
}
