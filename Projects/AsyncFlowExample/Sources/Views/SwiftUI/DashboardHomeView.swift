//
//  DashboardHomeView.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncViewModel
import SwiftUI

struct DashboardHomeView: View {
    @StateObject var viewModel: DashboardHomeViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                quickActionsSection
                featuresPreviewSection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .onAppear {
            viewModel.send(.onAppear)
        }
        .onDisappear {
            viewModel.send(.cleanup)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Welcome to AsyncFlow")
                .font(.title2)
                .fontWeight(.bold)

            Text("Explore all features below")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "list.bullet",
                    title: "Features",
                    color: .blue
                ) {
                    viewModel.send(.featureListTapped)
                }

                QuickActionButton(
                    icon: "lock.shield",
                    title: "Permissions",
                    color: .orange
                ) {
                    viewModel.send(.permissionFeatureTapped)
                }
            }
        }
    }

    private var featuresPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Features")
                    .font(.headline)

                Spacer()

                if viewModel.state.isLoading {
                    ProgressView()
                }
            }

            if viewModel.state.features.isEmpty && !viewModel.state.isLoading {
                EmptyStateView(
                    icon: "tray",
                    message: "No features available"
                )
            } else {
                ForEach(viewModel.state.features.prefix(4)) { feature in
                    FeatureRowView(
                        feature: feature,
                        isPermissionGranted: viewModel.state.grantedPermissions[feature.name] ?? false
                    )
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct FeatureRowView: View {
    let feature: Feature
    let isPermissionGranted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.name)
                    .font(.headline)

                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if feature.requiresPermission && !isPermissionGranted {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationView {
        DashboardHomeView(viewModel: DashboardHomeViewModel(permissionService: PermissionService()))
    }
}
