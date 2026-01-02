//
//  TestHelpers.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 2.
//

@testable import AsyncFlow
@testable import AsyncFlowExample
import Foundation
import Testing
import UIKit

// MARK: - Test Error

enum TestError: Error {
    case timeout(String)
}

// MARK: - Test Helpers

extension Test {
    @MainActor
    static func waitUntil(
        timeout: TimeInterval = 3.0,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() <= deadline else {
                #expect(Bool(false), "Timeout waiting for condition")
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    @MainActor
    static func wait(milliseconds: Int) async {
        try? await Task.sleep(nanoseconds: UInt64(milliseconds) * 1_000_000)
    }

    @MainActor
    static func expectNavigationStack(
        _ navigationController: UINavigationController,
        matches screens: [DemoStep.Screen],
        file _: StaticString = #file,
        line _: UInt = #line
    ) {
        let actualScreens = navigationController.viewControllers.compactMap {
            ($0 as? ScreenViewController)?.viewModel.state.config.screen
        }

        #expect(
            actualScreens == screens,
            "Expected stack \(screens) but got \(actualScreens)"
        )
    }
}

// MARK: - Test Fixtures

enum TestFixtures {
    @MainActor
    static func createScreenViewModel(
        screen: DemoStep.Screen,
        depth: Int = 0
    ) -> ScreenViewModel {
        return ScreenViewModel(screen: screen, depth: depth)
    }

    @MainActor
    static func createMainFlow() -> MainFlow {
        return MainFlow()
    }

    @MainActor
    static func createNavigationStack(_ screens: [DemoStep.Screen]) -> [UIViewController] {
        return screens.enumerated().map { index, screen in
            let viewModel = ScreenViewModel(screen: screen, depth: index)
            return ScreenViewController(viewModel: viewModel)
        }
    }

    static let screenConfigs: [DemoStep.Screen: ScreenConfig] = [
        .a: ScreenConfig.all[.a]!,
        .b: ScreenConfig.all[.b]!,
        .c: ScreenConfig.all[.c]!,
        .d: ScreenConfig.all[.d]!,
        .e: ScreenConfig.all[.e]!,
    ]
}

// MARK: - Mock Navigation Stack ViewModel

@MainActor
final class MockNavigationStackViewModel: ObservableObject {
    @Published var stack: [DemoStep.Screen] = [.a]
    var updateCallCount = 0
    var resetCallCount = 0

    func updateCurrentScreen(_ screen: DemoStep.Screen) {
        updateCallCount += 1
        if let index = stack.firstIndex(of: screen) {
            stack = Array(stack.prefix(through: index))
        } else {
            stack.append(screen)
        }
    }

    func resetToRoot() {
        resetCallCount += 1
        stack = [.a]
    }
}

// MARK: - Tags

extension Tag {
    @Tag static var viewModel: Self
    @Tag static var flow: Self
    @Tag static var navigation: Self
    @Tag static var integration: Self
    @Tag static var asyncViewModel: Self
    @Tag static var unit: Self
}
