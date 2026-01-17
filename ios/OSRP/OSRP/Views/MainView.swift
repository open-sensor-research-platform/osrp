//
//  MainView.swift
//  OSRP
//
//  Main dashboard view showing status and controls
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var statusViewModel = StatusViewModel()
    @State private var showHealthKitPermission = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OSRP")
                            .font(.system(size: 32, weight: .bold))

                        Text("Open Sensing Research Platform")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Version 0.1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // User Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("User")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        if let email = authViewModel.userEmail {
                            Text("Logged in as: \(email)")
                                .font(.body)
                        }

                        Text("Connection Status")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)

                        HStack {
                            Circle()
                                .fill(statusViewModel.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)

                            Text(statusViewModel.isConnected ? "Connected" : "Disconnected")
                                .font(.body)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)

                    // Collection Status Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Collection")
                            .font(.headline)

                        HStack {
                            Text(statusViewModel.isCollecting ? "Running" : "Stopped")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(statusViewModel.isCollecting ? .green : .primary)
                        }

                        Text("HealthKit data collection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)

                    // Pending Data Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pending Upload")
                            .font(.headline)

                        Text("\(statusViewModel.pendingRecords) records pending upload")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Text("Data Points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)

                        Text("\(statusViewModel.pendingRecords)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)

                    // Last Upload Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last Upload")
                            .font(.headline)

                        if let lastUpload = statusViewModel.lastUploadTime {
                            Text(lastUpload, style: .relative)
                                .font(.body)
                                .foregroundColor(.secondary)

                            Text(lastUpload, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)

                            Text(lastUpload, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never uploaded")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)

                    // Control Buttons
                    VStack(spacing: 12) {
                        if statusViewModel.isCollecting {
                            Button(action: {
                                statusViewModel.stopCollection()
                            }) {
                                Label("Stop Collection", systemImage: "stop.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        } else {
                            Button(action: {
                                Task {
                                    if await statusViewModel.isHealthKitAuthorized() {
                                        statusViewModel.startCollection()
                                    } else {
                                        showHealthKitPermission = true
                                    }
                                }
                            }) {
                                Label("Start Collection", systemImage: "play.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }

                        Button(action: {
                            statusViewModel.uploadNow()
                        }) {
                            Label("Upload Now", systemImage: "icloud.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button(action: {
                            statusViewModel.refreshStatus()
                        }) {
                            Label("Refresh Status", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
        .onAppear {
            statusViewModel.startPeriodicRefresh()
        }
        .sheet(isPresented: $showHealthKitPermission) {
            HealthKitPermissionView(isPresented: $showHealthKitPermission) {
                statusViewModel.startCollection()
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthViewModel())
}
