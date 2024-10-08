//
//  CentralManager.swift
//  CentralSandbox
//
//  Created by Giovane Barreira on 9/27/24.
//


import CoreBluetooth
import SwiftUI
import os.log

class CentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?

    @Published var isScanning = false
    @Published var statusMessage: String = "Scanning is off."
    @Published var receivedMessage: String = ""
    @Published var estimatedDistance: String = "Distance: N/A"
    @Published var rssiValue: String = "RSSI: N/A"

    private let peripheralKey = "savedPeripheralIdentifier"
    private let distanceThreshold: Double = 1.5
    private let rssiAtOneMeter: Double = -50
    private let pathLossExponent: Double = 2.0

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func toggleScanning() {
        if isScanning {
            centralManager.stopScan()
            isScanning = false
            statusMessage = "Scanning is off."
            os_log("Stopped scanning.")
        } else {
            startScanning()
        }
    }

    func startScanning() {
        centralManager.scanForPeripherals(withServices: [CBUUID(string: "12345678-1234-5678-1234-567812345678")], options: nil)
        isScanning = true
        statusMessage = "Scanning for peripherals..."
        os_log("Started scanning for peripherals. [Beacon]")
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            statusMessage = "Central is powered on."
            startScanning()
        } else {
            statusMessage = "Central is not powered on."
            os_log("Central is not powered on.[Beacon]")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        os_log("Discovered %@ with RSSI: %@", peripheral.name ?? "unknown", RSSI)

        if discoveredPeripheral == nil || discoveredPeripheral!.identifier != peripheral.identifier {
            discoveredPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
            statusMessage = "Connecting to \(peripheral.name ?? "unknown")"
            os_log("Connecting to %@ [Beacon]", peripheral.name ?? "unknown")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusMessage = "Connected to \(peripheral.name ?? "unknown")"
        os_log("Connected to %@", peripheral.name ?? "unknown")
        peripheral.delegate = self
        peripheral.readRSSI()
        os_log("Connected to peripheral: %@ [Beacon]", peripheral.name ?? "unknown")
        peripheral.discoverServices([CBUUID(string: "12345678-1234-5678-1234-567812345678")])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error = error {
            os_log("Error discovering services: %@ [Beacon]", error.localizedDescription)
            return
        }
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics([CBUUID(string: "87654321-4321-6789-4321-678987654321")], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error = error {
            os_log("Error discovering characteristics: %@ [Beacon]", error.localizedDescription)
            return
        }

        let service = peripheral.services?.first(where: { $0.uuid == CBUUID(string: "12345678-1234-5678-1234-567812345678") })
        let characteristic = service?.characteristics?.first(where: { $0.uuid == CBUUID(string: "87654321-4321-6789-4321-678987654321") })
        os_log("Discovered characteristic: %@", characteristic?.uuid.uuidString ?? "unknown")
        guard let characteristic else { return }
        peripheral.readValue(for: characteristic)

        // Send a message to the peripheral after connection
        sendMessageToPeripheral(peripheral: peripheral, message: "Hello from Central!")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == CBUUID(string: "87654321-4321-6789-4321-678987654321"),
              let value = characteristic.value else { return }

        let valueAsString = String(data: value, encoding: .utf8)
        os_log("Characteristic value: %@ [Beacon]", valueAsString ?? "nil")
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error = error {
            os_log("Error reading RSSI: %@ [Beacon]", error.localizedDescription)
            return
        }

        rssiValue = "RSSI: \(RSSI.intValue)"
        os_log("RSSI: %d [Beacon]", RSSI.intValue)
        let distance = calculateDistance(rssi: RSSI.doubleValue)
        estimatedDistance = String(format: "Distance: %.2f m", distance)

        if distance <= distanceThreshold {
            statusMessage = "In range: \(distance) m"
            os_log("In range: %.2f m", distance)
        } else {
            statusMessage = "Out of range: \(distance) m"
            os_log("Out of range: %.2f m", distance)
        }

        peripheral.readRSSI() // Optionally read RSSI periodically
    }

    private func sendMessageToPeripheral(peripheral: CBPeripheral, message: String) {
        guard let service = peripheral.services?.first(where: { $0.uuid == CBUUID(string: "12345678-1234-5678-1234-567812345678") }),
              let characteristic = service.characteristics?.first(where: { $0.uuid == CBUUID(string: "87654321-4321-6789-4321-678987654321") }) else {
            os_log("Characteristic not found")
            return
        }

        let data = message.data(using: .utf8)
        peripheral.writeValue(data!, for: characteristic, type: .withResponse)
        os_log("Sent message to peripheral: %@ [Beacon]", message)
    }

    private func calculateDistance(rssi: Double) -> Double {
        return pow(10, (rssiAtOneMeter - rssi) / (10 * pathLossExponent))
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        // You can handle any logic related to modified services here if needed
        os_log("Services modified for peripheral: %@ [Beacon]", peripheral.identifier.uuidString)
    }
}
