import SwiftUI

/// 네비게이션 스택을 시각화하는 View
struct NavigationStackView: View {
    @EnvironmentObject var viewModel: NavigationStackViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Stack Visualization
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.stack.enumerated()), id: \.offset) { index, screen in
                        HStack(spacing: 8) {
                            // Screen Card
                            ScreenCardView(
                                config: ScreenConfig.all[screen]!,
                                isActive: index == viewModel.stack.count - 1
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))

                            // Arrow (마지막 카드 제외)
                            if index < viewModel.stack.count - 1 {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .frame(height: 100)
            .background(Color(UIColor.systemBackground))
        }
        .frame(height: NavigationStackViewModel.fixedHeight)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var headerView: some View {
        HStack {
            Text("Navigation Stack")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Text("\(viewModel.stack.count) screen\(viewModel.stack.count > 1 ? "s" : "")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var viewModel: NavigationStackViewModel = {
            let sharedVM = NavigationStackViewModel.shared
            sharedVM.stack = [.a, .b, .c]
            return sharedVM
        }()

        var body: some View {
            VStack {
                NavigationStackView()
                    .environmentObject(viewModel)

                Spacer()

                // Test Buttons
                VStack {
                    Button("Push D") {
                        viewModel.updateCurrentScreen(.d)
                    }
                    Button("Pop") {
                        if viewModel.stack.count > 1 {
                            let prev = viewModel.stack[viewModel.stack.count - 2]
                            viewModel.updateCurrentScreen(prev)
                        }
                    }
                    Button("Reset to Root") {
                        viewModel.resetToRoot()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .background(Color.gray.opacity(0.1))
        }
    }

    return PreviewWrapper()
}
