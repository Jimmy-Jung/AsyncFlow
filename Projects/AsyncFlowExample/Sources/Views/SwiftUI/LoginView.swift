//
//  LoginView.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncViewModel
import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: LoginViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 60)

                logoSection

                formSection

                actionButtonsSection

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.send(.cleanup)
        }
    }

    private var logoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue)

            Text("AsyncFlow Demo")
                .font(.title)
                .fontWeight(.bold)

            Text("Sign in to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 20)
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            TextField("Email", text: Binding(
                get: { viewModel.state.email },
                set: { viewModel.send(.emailChanged($0)) }
            ))
            .textFieldStyle(.roundedBorder)
            .textContentType(.emailAddress)
            .autocapitalization(.none)
            .keyboardType(.emailAddress)

            SecureField("Password", text: Binding(
                get: { viewModel.state.password },
                set: { viewModel.send(.passwordChanged($0)) }
            ))
            .textFieldStyle(.roundedBorder)
            .textContentType(.password)

            if let errorMessage = viewModel.state.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button {
                viewModel.send(.loginTapped)
            } label: {
                Group {
                    if viewModel.state.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Login")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.state.isLoading)

            HStack {
                Button {
                    viewModel.send(.registerTapped)
                } label: {
                    Text("Create Account")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                Spacer()

                Button {
                    viewModel.send(.forgotPasswordTapped)
                } label: {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        LoginView(viewModel: LoginViewModel(authService: AuthService()))
    }
}
