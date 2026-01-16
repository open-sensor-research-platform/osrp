//
//  ContentView.swift
//  OSRP
//
//  Main content view - placeholder for development
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("OSRP")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.blue)

            Text("Open Sensing Research Platform")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Version 0.1.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
