//
//  OSRPApp.swift
//  OSRP
//
//  Open Sensing Research Platform
//  iOS Application Entry Point
//

import SwiftUI

@main
struct OSRPApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        // Register background tasks
        Task { @MainActor in
            BackgroundTaskManager.shared.registerBackgroundTasks()
        }
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
