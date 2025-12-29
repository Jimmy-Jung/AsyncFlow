//
//  ProfileView.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncViewModel
import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel

    var body: some View {
        List {
            Section {
                if let user = viewModel.state.user {
                    profileHeader(user: user)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }

            Section("Account Information") {
                if let user = viewModel.state.user {
                    InfoRow(label: "Name", value: user.name)
                    InfoRow(label: "Email", value: user.email)
                    InfoRow(label: "User ID", value: user.id.uuidString.prefix(8) + "...")
                }
            }

            Section {
                Button(role: .destructive) {
                    viewModel.send(.back)
                } label: {
                    HStack {
                        Image(systemName: "arrow.backward")
                        Text("Back to Settings")
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            viewModel.send(.onAppear)
        }
        .onDisappear {
            viewModel.send(.cleanup)
        }
    }

    private func profileHeader(user: User) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 80, height: 80)
                .overlay {
                    Text(user.name.prefix(1))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    NavigationView {
        ProfileView(viewModel: ProfileViewModel(authService: AuthService()))
    }
}
