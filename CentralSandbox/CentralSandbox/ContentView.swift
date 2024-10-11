//
//  ContentView.swift
//  CentralSandbox
//
//  Created by Giovane Barreira on 9/25/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var beaconManager = BeaconManager()
    
    var body: some View {
        VStack(alignment: .center) {
            if beaconManager.beaconDetected {
                BeaconMessage(message: BeaconConnectionStatusMessage.detected)
                Text("Distance: \(beaconManager.beaconDistance)")
            } else {
                BeaconMessage(message: BeaconConnectionStatusMessage.notDetected)
            }
        }
    }
}

struct BeaconMessage: View {
    var message: String
    let image = "iphone.gen1.radiowaves.left.and.right"
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: image)
                    .scaleEffect(isAnimating ? 1.5 : 1)
                    .animation(
                        isAnimating ? .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                .default,
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                Text(message).font(.title)
            }
        }
    }
}

struct BeaconConnectionStatusMessage {
    static let detected = "Beacon detected"
    static let notDetected = "No Beacons detected"
}

#Preview {
    ContentView()
}
