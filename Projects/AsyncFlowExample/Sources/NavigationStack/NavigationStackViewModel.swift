import Combine
import Foundation
import SwiftUI

/// 네비게이션 스택 상태를 관리하는 ViewModel
@MainActor
final class NavigationStackViewModel: ObservableObject {
    // MARK: - Singleton

    static let shared = NavigationStackViewModel()

    // MARK: - Published Properties

    @Published var stack: [DemoStep.Screen] = []

    // 고정 높이
    static let fixedHeight: CGFloat = 180

    // MARK: - Initialization

    private init() {
        // 초기 상태: Screen A만 존재
        stack = [.a]
    }

    // MARK: - Public Methods

    /// 현재 화면 업데이트 (UINavigationControllerDelegate에서 호출)
    func updateCurrentScreen(_ screen: DemoStep.Screen) {
        // 스택에서 해당 화면의 위치 찾기
        if let index = stack.firstIndex(of: screen) {
            // Pop: 해당 화면까지만 남기고 나머지 제거
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                stack = Array(stack.prefix(through: index))
            }
        } else {
            // Push: 새 화면 추가
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                stack.append(screen)
            }
        }

        print("📚 Stack updated: \(stack.map { $0.rawValue.uppercased() }.joined(separator: " → "))")
    }

    /// 스택 초기화 (루트로 이동)
    func resetToRoot() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            stack = [.a]
        }
    }
}
