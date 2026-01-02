//
//  NavigationPatternTests.swift
//  AsyncFlowTests
//
//  Created by jimmy on 2026. 1. 1.
//

@testable import AsyncFlow
import Foundation
import Testing

#if canImport(UIKit)
    import UIKit

    @Suite("Navigation Pattern Tests")
    struct NavigationPatternTests {
        // MARK: - Basic Navigation Tests

        @Test("Navigate to screen adds to stack")
        @MainActor
        func navigateToScreen() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = OneStepper(withSingleStep: NavStep.screenA)

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 1 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 1)
        }

        @Test("Push multiple screens")
        @MainActor
        func pushMultipleScreens() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(NavStep.screenB)
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 2 }

            stepper.emit(NavStep.screenC)
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 3 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 3)
        }

        // MARK: - Go Back Tests

        @Test("GoBack pops one screen")
        @MainActor
        func goBackPopsOneScreen() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(NavStep.screenB)
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 2 }

            stepper.emit(NavStep.goBack)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 1 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 1)
        }

        @Test("GoBack2 pops two screens")
        @MainActor
        func goBack2PopsTwoScreens() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(NavStep.screenB)
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 2 }

            stepper.emit(NavStep.screenC)
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 3 }

            stepper.emit(NavStep.goBack2)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 1 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 1)
        }

        @Test("GoBack3 pops three screens")
        @MainActor
        func goBack3PopsThreeScreens() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(NavStep.screenB)
            stepper.emit(NavStep.screenC)
            stepper.emit(NavStep.screenD)
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 4 }

            stepper.emit(NavStep.goBack3)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 1 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 1)
        }

        // MARK: - Go To Root Tests

        @Test("GoToRoot returns to root screen")
        @MainActor
        func goToRootReturnsToRoot() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(NavStep.screenB)
            stepper.emit(NavStep.screenC)
            stepper.emit(NavStep.screenD)
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 4 }

            stepper.emit(NavStep.goToRoot)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 1 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 1)
        }

        // MARK: - Go To Specific Tests

        @Test("GoToSpecific navigates to existing screen")
        @MainActor
        func goToSpecificExisting() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(NavStep.screenB)
            stepper.emit(NavStep.screenC)
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 3 }

            stepper.emit(NavStep.goToSpecific(.b))
            await Test.waitUntil { flow.navigationController.viewControllers.count == 2 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 2)
        }

        @Test("GoToSpecific creates new screen if not exists")
        @MainActor
        func goToSpecificNew() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(NavStep.goToSpecific(.b))
            await Test.waitUntil { flow.navigationController.viewControllers.count == 2 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 2)
        }

        // MARK: - Complex Navigation Scenarios

        @Test("Navigate back and forth")
        @MainActor
        func navigateBackAndForth() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            // A → B
            stepper.emit(NavStep.screenB)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 2 }

            // B → A
            stepper.emit(NavStep.goBack)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 1 }

            // A → B → C
            stepper.emit(NavStep.screenB)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 2 }
            stepper.emit(NavStep.screenC)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 3 }

            // C → A
            stepper.emit(NavStep.goToRoot)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 1 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 1)
        }

        @Test("Navigate with mixed patterns")
        @MainActor
        func navigateWithMixedPatterns() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            // A → B → C → D
            stepper.emit(NavStep.screenB)
            stepper.emit(NavStep.screenC)
            stepper.emit(NavStep.screenD)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 4 }

            // D → B (goToSpecific)
            stepper.emit(NavStep.goToSpecific(.b))
            await Test.waitUntil { flow.navigationController.viewControllers.count == 2 }

            // B → C → D
            stepper.emit(NavStep.screenC)
            stepper.emit(NavStep.screenD)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 4 }

            // D → C (goBack)
            stepper.emit(NavStep.goBack)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 3 }

            // C → A (goBack2)
            stepper.emit(NavStep.goBack2)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 1 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 1)
        }

        // MARK: - Edge Cases

        @Test("GoBack when already at root")
        @MainActor
        func goBackAtRoot() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(NavStep.goBack)
            try? await Task.sleep(nanoseconds: 100_000_000)

            // Then - root에서는 뒤로가기 무시
            #expect(flow.navigationController.viewControllers.count == 1)
        }

        @Test("GoBack2 when only one screen in stack")
        @MainActor
        func goBack2WithOneScreen() async {
            // Given
            let flow = TestNavigationFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(NavStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(NavStep.screenB)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 2 }

            stepper.emit(NavStep.goBack2)
            try? await Task.sleep(nanoseconds: 100_000_000)

            // Then - 2단계 뒤로가기 불가능하면 무시
            #expect(flow.navigationController.viewControllers.count == 2)
        }
    }

    // MARK: - Test Types

    enum NavStep: Step, Equatable {
        case screenA
        case screenB
        case screenC
        case screenD

        case goBack
        case goBack2
        case goBack3
        case goToRoot
        case goToSpecific(Screen)

        enum Screen: String, Equatable {
            case a, b, c, d
        }
    }

    @MainActor
    final class TestNavigationFlow: Flow {
        let navigationController = UINavigationController()
        var root: Presentable { navigationController }

        func navigate(to step: Step) -> FlowContributors {
            guard let navStep = step as? NavStep else { return .none }

            switch navStep {
            case .screenA:
                return navigateToScreen(.a)
            case .screenB:
                return navigateToScreen(.b)
            case .screenC:
                return navigateToScreen(.c)
            case .screenD:
                return navigateToScreen(.d)
            case .goBack:
                return goBack(count: 1)
            case .goBack2:
                return goBack(count: 2)
            case .goBack3:
                return goBack(count: 3)
            case .goToRoot:
                return goToRoot()
            case let .goToSpecific(screen):
                return goToSpecific(screen: screen)
            }
        }

        private func navigateToScreen(_ screen: NavStep.Screen) -> FlowContributors {
            let vc = TestScreenViewController()
            vc.screenIdentifier = screen.rawValue
            navigationController.pushViewController(vc, animated: false)
            return .none
        }

        private func goBack(count: Int) -> FlowContributors {
            guard navigationController.viewControllers.count > count else {
                return .none
            }

            let targetIndex = navigationController.viewControllers.count - count - 1
            let targetVC = navigationController.viewControllers[targetIndex]
            navigationController.popToViewController(targetVC, animated: false)

            return .none
        }

        private func goToRoot() -> FlowContributors {
            navigationController.popToRootViewController(animated: false)
            return .none
        }

        private func goToSpecific(screen: NavStep.Screen) -> FlowContributors {
            // 이미 스택에 있는지 확인
            if let existingVC = findViewController(for: screen) {
                navigationController.popToViewController(existingVC, animated: false)
                return .none
            }

            // 없으면 새로 push
            return navigateToScreen(screen)
        }

        private func findViewController(for screen: NavStep.Screen) -> UIViewController? {
            return navigationController.viewControllers.first { viewController in
                guard let testVC = viewController as? TestScreenViewController else { return false }
                return testVC.screenIdentifier == screen.rawValue
            }
        }
    }

    final class TestScreenViewController: UIViewController {
        var screenIdentifier: String = ""
    }

#endif
