//
//  RealWorldScenarioTests.swift
//  AsyncFlowTests
//
//  Created by jimmy on 2026. 1. 1.
//

@testable import AsyncFlow
import Foundation
import Testing

#if canImport(UIKit)
    import UIKit

    @Suite("Real-world Scenario Tests")
    struct RealWorldScenarioTests {
        // MARK: - App Launch Flow

        @Test("App launch with conditional navigation")
        @MainActor
        func appLaunchConditionalNavigation() async {
            // Given
            let appCoordinator = FlowCoordinator()
            let appFlow = AppLaunchFlow(isLoggedIn: false)
            let appStepper = OneStepper(withSingleStep: AppLaunchStep.launch)

            // When
            appCoordinator.coordinate(flow: appFlow, with: appStepper)
            await Test.waitUntil { appFlow.navigateCallCount >= 2 }

            // Then - 로그인 안되어 있으므로 로그인 화면으로 (launch -> login)
            #expect(appFlow.lastNavigatedStep == .login)
        }

        @Test("App launch when already logged in")
        @MainActor
        func appLaunchWhenLoggedIn() async {
            // Given
            let appCoordinator = FlowCoordinator()
            let appFlow = AppLaunchFlow(isLoggedIn: true)
            let appStepper = OneStepper(withSingleStep: AppLaunchStep.launch)

            // When
            appCoordinator.coordinate(flow: appFlow, with: appStepper)
            await Test.waitUntil { appFlow.navigateCallCount >= 1 }

            // Then - 로그인 되어있으므로 홈으로
            #expect(appFlow.lastNavigatedStep == .home)
        }

        // MARK: - Tab-based Navigation

        @Test("TabBar flow with three tabs")
        @MainActor
        func tabBarFlowWithThreeTabs() async {
            // Given
            let coordinator = FlowCoordinator()
            let tabBarFlow = TabBarFlow()
            let stepper = OneStepper(withSingleStep: TabStep.initialize)

            // When
            coordinator.coordinate(flow: tabBarFlow, with: stepper)
            await Test.waitUntil { tabBarFlow.tabsInitialized }

            // Then
            #expect(tabBarFlow.homeFlow != nil)
            #expect(tabBarFlow.searchFlow != nil)
            #expect(tabBarFlow.profileFlow != nil)
        }

        @Test("Switch between tabs")
        @MainActor
        func switchBetweenTabs() async {
            // Given
            let coordinator = FlowCoordinator()
            let tabBarFlow = TabBarFlow()
            let stepper = MockStepper()
            stepper.setInitialStep(TabStep.initialize)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: tabBarFlow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { tabBarFlow.tabsInitialized }

            stepper.emit(TabStep.selectTab(.home))
            await Test.waitUntil { tabBarFlow.selectedTab == .home }

            stepper.emit(TabStep.selectTab(.search))
            await Test.waitUntil { tabBarFlow.selectedTab == .search }

            // Then
            #expect(tabBarFlow.selectedTab == .search)
        }

        // MARK: - Modal Presentation

        @Test("Present modal flow")
        @MainActor
        func presentModalFlow() async {
            // Given
            let coordinator = FlowCoordinator()
            let mainFlow = MainModalFlow()
            let stepper = MockStepper()
            stepper.setInitialStep(ModalStep.main)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: mainFlow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { mainFlow.navigateCallCount >= 1 }

            stepper.emit(ModalStep.presentModal)
            await Test.waitUntil { mainFlow.modalFlow != nil }

            // Then
            #expect(mainFlow.modalFlow != nil)
        }

        @Test("Dismiss modal and forward result")
        @MainActor
        func dismissModalAndForwardResult() async {
            // Given
            let coordinator = FlowCoordinator()
            let mainFlow = MainModalFlow()
            let stepper = MockStepper()
            stepper.setInitialStep(ModalStep.main)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: mainFlow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { mainFlow.navigateCallCount >= 1 }

            stepper.emit(ModalStep.presentModal)
            await Test.waitUntil(timeout: 2.0) { mainFlow.modalFlow != nil }

            guard let modal = mainFlow.modalFlow else {
                #expect(Bool(false), "Modal flow should exist")
                return
            }

            // Modal이 완료되면 stepper를 통해 전달
            stepper.emit(ModalStep.modalComplete(result: "Result"))
            await Test.waitUntil(timeout: 2.0) { mainFlow.receivedResult == "Result" }

            // Then
            #expect(mainFlow.receivedResult == "Result")
        }

        // MARK: - Authentication Flow

        @Test("Login flow success")
        @MainActor
        func loginFlowSuccess() async {
            // Given
            let coordinator = FlowCoordinator()
            let authFlow = AuthFlow()
            let stepper = MockStepper()
            stepper.setInitialStep(AuthStep.showLogin)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: authFlow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { authFlow.navigateCallCount >= 1 }

            stepper.emit(AuthStep.loginSuccess(token: "abc123"))
            await Test.waitUntil { authFlow.loginToken == "abc123" }

            // Then
            #expect(authFlow.loginToken == "abc123")
        }

        @Test("Login flow with permission check")
        @MainActor
        func loginFlowWithPermissionCheck() async {
            // Given
            let coordinator = FlowCoordinator()
            let authFlow = AuthFlow()
            let stepper = MockStepper()
            stepper.setInitialStep(AuthStep.showLogin)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: authFlow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { authFlow.navigateCallCount >= 1 }

            // 권한 없는 화면 접근 시도
            stepper.emit(AuthStep.requiresPermission)
            await Test.waitUntil { authFlow.blockedByPermission }

            // Then
            #expect(authFlow.blockedByPermission)
        }

        // MARK: - Onboarding Flow

        @Test("Onboarding complete flow")
        @MainActor
        func onboardingCompleteFlow() async {
            // Given
            let coordinator = FlowCoordinator()
            let onboardingFlow = OnboardingFlow()
            let stepper = MockStepper()
            stepper.setInitialStep(OnboardingStep.start)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: onboardingFlow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { onboardingFlow.navigateCallCount >= 1 }

            stepper.emit(OnboardingStep.page1)
            stepper.emit(OnboardingStep.page2)
            stepper.emit(OnboardingStep.page3)
            await Test.waitUntil { onboardingFlow.currentPage == 3 }

            stepper.emit(OnboardingStep.complete)
            await Test.waitUntil { onboardingFlow.completed }

            // Then
            #expect(onboardingFlow.completed)
        }

        // MARK: - Deep Navigation Stack

        @Test("Deep navigation with state preservation")
        @MainActor
        func deepNavigationStatePreservation() async {
            // Given
            let coordinator = FlowCoordinator()
            let navFlow = DeepNavigationFlow()
            let stepper = MockStepper()
            stepper.setInitialStep(DeepNavStep.level1)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: navFlow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { navFlow.stack.count == 1 }

            stepper.emit(DeepNavStep.level2)
            stepper.emit(DeepNavStep.level3)
            stepper.emit(DeepNavStep.level4)
            await Test.waitUntil { navFlow.stack.count == 4 }

            stepper.emit(DeepNavStep.backToLevel(2))
            await Test.waitUntil { navFlow.stack.count == 2 }

            // Then
            #expect(navFlow.stack.count == 2)
            #expect(navFlow.stack.last == "level2")
        }

        // MARK: - Error Handling

        @Test("Error recovery flow")
        @MainActor
        func errorRecoveryFlow() async {
            // Given
            let coordinator = FlowCoordinator()
            let errorFlow = ErrorHandlingFlow()
            let stepper = MockStepper()
            stepper.setInitialStep(ErrorStep.normal)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: errorFlow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { errorFlow.navigateCallCount >= 1 }

            stepper.emit(ErrorStep.error(message: "Network error"))
            await Test.waitUntil { errorFlow.lastError == "Network error" }

            stepper.emit(ErrorStep.retry)
            await Test.waitUntil { errorFlow.retryCount == 1 }

            // Then
            #expect(errorFlow.lastError == "Network error")
            #expect(errorFlow.retryCount == 1)
        }
    }

    // MARK: - Test Flows

    enum AppLaunchStep: Step, Equatable {
        case launch
        case login
        case home
    }

    @MainActor
    final class AppLaunchFlow: Flow {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        let isLoggedIn: Bool
        var navigateCallCount = 0
        var lastNavigatedStep: AppLaunchStep?

        init(isLoggedIn: Bool) {
            self.isLoggedIn = isLoggedIn
        }

        func navigate(to step: Step) -> FlowContributors {
            navigateCallCount += 1

            guard let appStep = step as? AppLaunchStep else { return .none }
            lastNavigatedStep = appStep

            switch appStep {
            case .launch:
                let nextStep: AppLaunchStep = isLoggedIn ? .home : .login
                return .one(flowContributor: .forwardToCurrentFlow(withStep: nextStep))
            case .login, .home:
                return .none
            }
        }
    }

    enum TabStep: Step, Equatable {
        case initialize
        case selectTab(Tab)

        enum Tab: Equatable {
            case home, search, profile
        }
    }

    @MainActor
    final class TabBarFlow: Flow {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        var homeFlow: MockFlow?
        var searchFlow: MockFlow?
        var profileFlow: MockFlow?
        var tabsInitialized = false
        var selectedTab: TabStep.Tab?

        func navigate(to step: Step) -> FlowContributors {
            guard let tabStep = step as? TabStep else { return .none }

            switch tabStep {
            case .initialize:
                homeFlow = MockFlow()
                searchFlow = MockFlow()
                profileFlow = MockFlow()
                tabsInitialized = true
                return .none
            case let .selectTab(tab):
                selectedTab = tab
                return .none
            }
        }
    }

    enum ModalStep: Step, Equatable {
        case main
        case presentModal
        case modalComplete(result: String)
    }

    @MainActor
    final class MainModalFlow: Flow {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        var navigateCallCount = 0
        var modalFlow: ModalContentFlow?
        var receivedResult: String?

        func navigate(to step: Step) -> FlowContributors {
            navigateCallCount += 1

            guard let modalStep = step as? ModalStep else { return .none }

            switch modalStep {
            case .main:
                return .none
            case .presentModal:
                let modal = ModalContentFlow()
                modalFlow = modal
                return .one(flowContributor: .contribute(
                    withNextPresentable: modal,
                    withNextStepper: OneStepper(withSingleStep: TestStep.initial)
                ))
            case let .modalComplete(result):
                receivedResult = result
                return .none
            }
        }
    }

    @MainActor
    final class ModalContentFlow: Flow, FlowStepper {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        let steps = AsyncReplaySubject<Step>(bufferSize: 1)

        func navigate(to _: Step) -> FlowContributors {
            .none
        }

        func complete(with result: String) {
            steps.send(ModalStep.modalComplete(result: result))
        }
    }

    enum AuthStep: Step, Equatable {
        case showLogin
        case loginSuccess(token: String)
        case requiresPermission
    }

    @MainActor
    final class AuthFlow: Flow {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        var navigateCallCount = 0
        var loginToken: String?
        var blockedByPermission = false

        func adapt(step: Step) async -> Step {
            guard let authStep = step as? AuthStep else { return step }

            if case .requiresPermission = authStep {
                blockedByPermission = true
                return NoneStep()
            }

            return step
        }

        func navigate(to step: Step) -> FlowContributors {
            navigateCallCount += 1

            guard let authStep = step as? AuthStep else { return .none }

            switch authStep {
            case .showLogin:
                return .none
            case let .loginSuccess(token):
                loginToken = token
                return .none
            case .requiresPermission:
                return .none
            }
        }
    }

    enum OnboardingStep: Step, Equatable {
        case start
        case page1
        case page2
        case page3
        case complete
    }

    @MainActor
    final class OnboardingFlow: Flow {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        var navigateCallCount = 0
        var currentPage = 0
        var completed = false

        func navigate(to step: Step) -> FlowContributors {
            navigateCallCount += 1

            guard let onboardingStep = step as? OnboardingStep else { return .none }

            switch onboardingStep {
            case .start:
                currentPage = 0
                return .none
            case .page1:
                currentPage = 1
                return .none
            case .page2:
                currentPage = 2
                return .none
            case .page3:
                currentPage = 3
                return .none
            case .complete:
                completed = true
                return .none
            }
        }
    }

    enum DeepNavStep: Step, Equatable {
        case level1
        case level2
        case level3
        case level4
        case backToLevel(Int)
    }

    @MainActor
    final class DeepNavigationFlow: Flow {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        var stack: [String] = []

        func navigate(to step: Step) -> FlowContributors {
            guard let navStep = step as? DeepNavStep else { return .none }

            switch navStep {
            case .level1:
                stack = ["level1"]
            case .level2:
                stack.append("level2")
            case .level3:
                stack.append("level3")
            case .level4:
                stack.append("level4")
            case let .backToLevel(level):
                if level > 0 && level <= stack.count {
                    stack = Array(stack.prefix(level))
                }
            }

            return .none
        }
    }

    enum ErrorStep: Step, Equatable {
        case normal
        case error(message: String)
        case retry
    }

    @MainActor
    final class ErrorHandlingFlow: Flow {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        var navigateCallCount = 0
        var lastError: String?
        var retryCount = 0

        func navigate(to step: Step) -> FlowContributors {
            navigateCallCount += 1

            guard let errorStep = step as? ErrorStep else { return .none }

            switch errorStep {
            case .normal:
                return .none
            case let .error(message):
                lastError = message
                return .none
            case .retry:
                retryCount += 1
                return .none
            }
        }
    }

#endif
