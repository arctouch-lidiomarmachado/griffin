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
        VStack {
            Text("Beacon Distance")
                .font(.largeTitle)
                .padding()

            Text(beaconManager.beaconDistance)
                .font(.title)
                .padding()

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
