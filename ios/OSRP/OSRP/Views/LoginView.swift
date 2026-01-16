//
//  LoginView.swift
//  OSRP
//
//  Login screen with Cognito authentication
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
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
                    .padding(.top, 40)

                    // Login Form
                    VStack(spacing: 16) {
                        Text("Login")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Email Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("email@example.com", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.password)
                        }

                        // Error Message
                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Login Button
                        Button(action: {
                            Task {
                                await authViewModel.login(email: email, password: password)
                            }
                        }) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Login")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)

                    // Information
                    VStack(spacing: 8) {
                        Text("Secure Authentication")
                            .font(.caption)
                            .fontWeight(.bold)

                        Text("Your credentials are securely transmitted using AWS Cognito authentication")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
