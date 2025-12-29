//
//  AboutView.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncViewModel
import SwiftUI

struct AboutView: View {
    @StateObject var viewModel: AboutViewModel

    var body: some View {
        List {
            Section {
                appIconSection
            }

            Section("App Information") {
                InfoRow(label: "Version", value: viewModel.state.version)
                InfoRow(label: "Build", value: viewModel.state.build)
            }

            Section("Technologies") {
                TechnologyRow(
                    name: "AsyncFlow",
                    description: "Swift Concurrency 기반 네비게이션 프레임워크"
                )
                TechnologyRow(
                    name: "AsyncViewModel",
                    description: "단방향 데이터 흐름 ViewModel 라이브러리"
                )
                TechnologyRow(
                    name: "Swift Concurrency",
                    description: "async/await, Actor 모델"
                )
            }

            Section("Developer") {
                InfoRow(label: "Author", value: "정준영")
                InfoRow(label: "Email", value: "joony300@gmail.com")
            }

            Section {
                Link(destination: URL(string: "https://github.com/Jimmy-Jung/AsyncFlow")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("GitHub Repository")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("About")
        .onAppear {
            viewModel.send(.onAppear)
        }
        .onDisappear {
            viewModel.send(.cleanup)
        }
    }

    private var appIconSection: some View {
        HStack {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)

                Text(viewModel.state.appName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Demo Application")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical)
    }
}

struct TechnologyRow: View {
    let name: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        AboutView(viewModel: AboutViewModel())
    }
}
