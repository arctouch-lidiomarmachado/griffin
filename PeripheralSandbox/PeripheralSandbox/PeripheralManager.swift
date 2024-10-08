//
//  PeripheralManager.swift
//  PeripheralSandbox
//
//  Created by Giovane Barreira on 9/24/24.
//


import CoreBluetooth
import UIKit
import SwiftUI
import os.log

class PeripheralManager: NSObject, CBPeripheralManagerDelegate, ObservableObject {
    var peripheralManager: CBPeripheralManager!
    var advertisementData: [String: Any]?
    var characteristicValue: Data { Date().formatted().data(using: .utf8)! }

    @Published var isAdvertising = false
    @Published var statusMessage: String = "Peripheral is not advertising."
    @Published var receivedMessage: String = "" // New property to store the received message
    var serviceUUID = CBUUID(string: "12345678-1234-5678-1234-567812345678")
    let characteristicUUID = CBUUID(string: "87654321-4321-6789-4321-678987654321")

    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func addServices() {
        let myChar1 = CBMutableCharacteristic(type: characteristicUUID, properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        let myService = CBMutableService(type: serviceUUID, primary: true)
        myService.characteristics = [myChar1]
        peripheralManager.add(myService)
        startAdvertising()
    }

    func startAdvertising() {
        if !isAdvertising {
            advertisementData = [CBAdvertisementDataLocalNameKey: "MyPeripheral", CBAdvertisementDataServiceUUIDsKey: [serviceUUID]]
            peripheralManager.startAdvertising(advertisementData)
            isAdvertising = true
            statusMessage = "Advertising started."
        }
    }

    func stopAdvertising() {
        if isAdvertising {
            peripheralManager.stopAdvertising()
            isAdvertising = false
            statusMessage = "Advertising stopped."
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            statusMessage = "Peripheral is powered on."
            addServices()
        } else {
            statusMessage = "Peripheral is not powered on."
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == characteristicUUID {
            request.value = characteristicValue
            peripheralManager.respond(to: request, withResult: .success)
        } else {
            peripheralManager.respond(to: request, withResult: .attributeNotFound)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == characteristicUUID, let value = request.value {
                receivedMessage = String(data: value, encoding: .utf8) ?? "Unknown message"
                // Update the UI or notify observers
                DispatchQueue.main.async {
                    // Notify UI update
                    self.objectWillChange.send()
                }
                peripheralManager.respond(to: request, withResult: .success)
            } else {
                peripheralManager.respond(to: request, withResult: .attributeNotFound)
            }
        }
    }
}

