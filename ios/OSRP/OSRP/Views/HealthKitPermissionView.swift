//
//  HealthKitPermissionView.swift
//  OSRP
//
//  View for requesting HealthKit permissions
//

import SwiftUI

struct HealthKitPermissionView: View {
    @Binding var isPresented: Bool
    @State private var isRequesting = false
    @State private var errorMessage: String?

    var onAuthorized: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top, 40)

                // Title
                Text("HealthKit Permission Required")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // Description
                VStack(spacing: 12) {
                    Text("OSRP needs access to your HealthKit data to collect:")
                        .font(.body)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 8) {
                        PermissionRow(icon: "figure.walk", text: "Step Count")
                        PermissionRow(icon: "heart.fill", text: "Heart Rate")
                        PermissionRow(icon: "flame.fill", text: "Active Energy")
                        PermissionRow(icon: "figure.run", text: "Walking/Running Distance")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Privacy note
                Text("Your health data is encrypted and securely transmitted to AWS for research purposes only.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Allow button
                Button(action: {
                    requestPermission()
                }) {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Allow Access")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRequesting)
                .padding(.horizontal)

                // Cancel button
                Button(action: {
                    isPresented = false
                }) {
                    Text("Not Now")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func requestPermission() {
        isRequesting = true
        errorMessage = nil

        Task {
            do {
                let healthKitService = HealthKitService()
                try await healthKitService.requestAuthorization()

                // Check if authorized
                if await healthKitService.isAuthorized() {
                    isPresented = false
                    onAuthorized()
                } else {
                    errorMessage = "HealthKit access was not granted. Please enable it in Settings."
                }
            } catch {
                errorMessage = "Failed to request HealthKit permission: \(error.localizedDescription)"
            }

            isRequesting = false
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.body)

            Spacer()
        }
    }
}

#Preview {
    HealthKitPermissionView(isPresented: .constant(true)) {
        print("Authorized")
    }
}
