//
//  PeripheralView.swift
//  PeripheralSandbox
//
//  Created by Giovane Barreira on 9/24/24.
//

import SwiftUI

struct PeripheralView: View {
    @StateObject private var peripheralManager = PeripheralManager()

    var body: some View {
        VStack {
            Text(peripheralManager.statusMessage)
                .padding()
                .foregroundColor(.blue)
            Text("Received Message: \(peripheralManager.receivedMessage)")
                         .padding()

            Button(action: {
                peripheralManager.startAdvertising()
            }) {
                Text("Start Advertising")
            }
            .padding()

            Button(action: {
                peripheralManager.stopAdvertising()
            }) {
                Text("Stop Advertising")
            }
            .padding()
        }
        .onAppear {
            // Any additional setup if needed
        }
    }
}

#Preview {
    PeripheralView()
}
