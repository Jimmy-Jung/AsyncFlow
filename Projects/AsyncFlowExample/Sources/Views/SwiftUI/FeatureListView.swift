//
//  FeatureListView.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncViewModel
import SwiftUI

struct FeatureListView: View {
    @StateObject var viewModel: FeatureListViewModel

    var body: some View {
        List {
            ForEach(viewModel.state.features) { feature in
                FeatureCell(feature: feature)
                    .onTapGesture {
                        viewModel.send(.featureTapped(feature))
                    }
            }
        }
        .navigationTitle("Features")
        .overlay {
            if viewModel.state.isLoading {
                ProgressView()
            }
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
        .onDisappear {
            viewModel.send(.cleanup)
        }
    }
}

struct FeatureCell: View {
    let feature: Feature

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(feature.name)
                        .font(.headline)

                    if feature.requiresPermission {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        FeatureListView(viewModel: FeatureListViewModel())
    }
}
