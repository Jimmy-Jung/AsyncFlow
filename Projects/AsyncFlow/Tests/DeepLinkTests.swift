//
//  DeepLinkTests.swift
//  AsyncFlowTests
//
//  Created by jimmy on 2026. 1. 1.
//

@testable import AsyncFlow
import Foundation
import Testing

#if canImport(UIKit)
    import UIKit

    @Suite("DeepLink and Complex Navigation Tests")
    struct DeepLinkTests {
        // MARK: - DeepLink Tests

        @Test("DeepLink to specific screen from root")
        @MainActor
        func deepLinkFromRoot() async {
            // Given
            let flow = DeepLinkFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(DeepLinkStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(DeepLinkStep.deepLink(.c))
            await Test.waitUntil { flow.navigationController.viewControllers.count == 3 }

            // Then - A → B → C 순차 생성
            #expect(flow.navigationController.viewControllers.count == 3)
            let screens = flow.navigationController.viewControllers.compactMap {
                ($0 as? DeepLinkViewController)?.screenIdentifier
            }
            #expect(screens == ["a", "b", "c"])
        }

        @Test("DeepLink replaces entire stack")
        @MainActor
        func deepLinkReplacesStack() async {
            // Given
            let flow = DeepLinkFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(DeepLinkStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            // A → D → E
            stepper.emit(DeepLinkStep.screenD)
            stepper.emit(DeepLinkStep.screenE)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 3 }

            // DeepLink to B
            stepper.emit(DeepLinkStep.deepLink(.b))
            await Test.waitUntil {
                let screens = flow.navigationController.viewControllers.compactMap {
                    ($0 as? DeepLinkViewController)?.screenIdentifier
                }
                return screens == ["a", "b"]
            }

            // Then
            #expect(flow.navigationController.viewControllers.count == 2)
        }

        @Test("DeepLink to root screen")
        @MainActor
        func deepLinkToRoot() async {
            // Given
            let flow = DeepLinkFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(DeepLinkStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(DeepLinkStep.screenB)
            stepper.emit(DeepLinkStep.screenC)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 3 }

            stepper.emit(DeepLinkStep.deepLink(.a))
            await Test.waitUntil { flow.navigationController.viewControllers.count == 1 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 1)
        }

        // MARK: - Complex Navigation Scenarios

        @Test("Nested Flow with parent communication")
        @MainActor
        func nestedFlowParentCommunication() async {
            // Given
            let parentCoordinator = FlowCoordinator()
            let parentFlow = ParentFlow()
            let parentStepper = MockStepper()
            parentStepper.setInitialStep(ParentStep.main)

            var subscribed = false
            parentStepper.onObservationStart = { subscribed = true }

            // When
            parentCoordinator.coordinate(flow: parentFlow, with: parentStepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { parentFlow.navigateCallCount >= 1 }

            parentStepper.emit(ParentStep.openChild)
            await Test.waitUntil(timeout: 2.0) { parentFlow.childFlow != nil }

            guard parentFlow.childFlow != nil else {
                #expect(Bool(false), "Child flow should be created")
                return
            }

            // Child가 부모에게 직접 메시지 전달 (coordinator를 통하지 않고)
            parentStepper.emit(ParentStep.messageFromChild)
            await Test.waitUntil(timeout: 2.0) { parentFlow.receivedMessageFromChild }

            // Then
            #expect(parentFlow.receivedMessageFromChild)
        }

        @Test("Flow ending forwards step to parent")
        @MainActor
        func flowEndingForwardsToParent() async {
            // Given
            let parentCoordinator = FlowCoordinator()
            let parentFlow = ParentFlow()
            let parentStepper = MockStepper()
            parentStepper.setInitialStep(ParentStep.main)

            var subscribed = false
            parentStepper.onObservationStart = { subscribed = true }

            // When
            parentCoordinator.coordinate(flow: parentFlow, with: parentStepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { parentFlow.navigateCallCount >= 1 }

            parentStepper.emit(ParentStep.openChild)
            await Test.waitUntil(timeout: 2.0) { parentFlow.childFlow != nil }

            guard parentFlow.childFlow != nil else {
                #expect(Bool(false), "Child flow should be created")
                return
            }

            // Child flow 종료를 parent stepper로 전달
            parentStepper.emit(ParentStep.childCompleted)
            await Test.waitUntil(timeout: 2.0) { parentFlow.childCompletedReceived }

            // Then
            #expect(parentFlow.childCompletedReceived)
        }

        @Test("Multiple child flows sequentially")
        @MainActor
        func multipleChildFlowsSequentially() async {
            // Given
            let parentCoordinator = FlowCoordinator()
            let parentFlow = ParentFlow()
            let parentStepper = MockStepper()
            parentStepper.setInitialStep(ParentStep.main)

            var subscribed = false
            parentStepper.onObservationStart = { subscribed = true }

            // When
            parentCoordinator.coordinate(flow: parentFlow, with: parentStepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { parentFlow.navigateCallCount >= 1 }

            // First child
            parentStepper.emit(ParentStep.openChild)
            await Test.waitUntil(timeout: 2.0) { parentFlow.childFlow != nil }
            let firstChild = parentFlow.childFlow

            parentStepper.emit(ParentStep.childCompleted)
            await Test.waitUntil(timeout: 2.0) { parentFlow.childCompletedReceived }

            // Second child
            parentFlow.childCompletedReceived = false
            parentFlow.childFlow = nil
            parentStepper.emit(ParentStep.openChild)
            await Test.waitUntil(timeout: 2.0) { parentFlow.childFlow != nil && parentFlow.childFlow !== firstChild }

            // Then
            #expect(parentFlow.childFlow !== firstChild)
        }

        @Test("Coordinator handles rapid step emissions")
        @MainActor
        func rapidStepEmissions() async {
            // Given
            let flow = DeepLinkFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(DeepLinkStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            // 빠르게 연속 방출
            stepper.emit(DeepLinkStep.screenB)
            stepper.emit(DeepLinkStep.screenC)
            stepper.emit(DeepLinkStep.screenD)
            stepper.emit(DeepLinkStep.screenE)

            await Test.waitUntil { flow.navigationController.viewControllers.count == 5 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 5)
        }

        @Test("External step injection via navigate method")
        @MainActor
        func externalStepInjection() async {
            // Given
            let flow = DeepLinkFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(DeepLinkStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            // 외부에서 직접 Step 주입 (예: DeepLink, Push Notification)
            coordinator.navigate(to: DeepLinkStep.screenC)
            await Test.waitUntil { flow.navigationController.viewControllers.count == 2 }

            // Then
            #expect(flow.navigationController.viewControllers.count == 2)
        }

        @Test("Navigation with ForwardToCurrentFlow")
        @MainActor
        func forwardToCurrentFlow() async {
            // Given
            let flow = ForwardingFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(ForwardStep.initial)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigateCallCount >= 1 }

            stepper.emit(ForwardStep.triggerForward)
            await Test.waitUntil { flow.navigateCallCount >= 2 }

            // forwardToCurrentFlow는 비동기로 처리되므로 forwarded step이 처리될 때까지 대기
            await Test.waitUntil(timeout: 2.0) {
                flow.navigateCallCount >= 3 &&
                    flow.lastReceivedSteps.contains(where: { ($0 as? ForwardStep) == .forwarded })
            }

            // Then - initial, triggerForward, forwarded 총 3번 호출
            #expect(flow.navigateCallCount >= 3)
            #expect(flow.lastReceivedSteps.contains(where: { ($0 as? ForwardStep) == .forwarded }))
        }

        // MARK: - Edge Cases

        @Test("DeepLink to same screen")
        @MainActor
        func deepLinkToSameScreen() async {
            // Given
            let flow = DeepLinkFlow()
            let coordinator = FlowCoordinator()
            let stepper = MockStepper()
            stepper.setInitialStep(DeepLinkStep.screenA)

            var subscribed = false
            stepper.onObservationStart = { subscribed = true }

            // When
            coordinator.coordinate(flow: flow, with: stepper)
            await Test.waitUntil { subscribed }
            await Test.waitUntil { flow.navigationController.viewControllers.count >= 1 }

            stepper.emit(DeepLinkStep.deepLink(.a))
            await Test.waitUntil(timeout: 0.5) { flow.navigationController.viewControllers.count == 1 }

            // Then - root로 돌아가므로 1개 유지
            #expect(flow.navigationController.viewControllers.count == 1)
        }
    }

    // MARK: - Test Types

    enum DeepLinkStep: Step, Equatable {
        case screenA
        case screenB
        case screenC
        case screenD
        case screenE
        case deepLink(Screen)

        enum Screen: String, Equatable, CaseIterable {
            case a, b, c, d, e
        }
    }

    @MainActor
    final class DeepLinkFlow: Flow {
        let navigationController = UINavigationController()
        var root: Presentable { navigationController }

        func navigate(to step: Step) -> FlowContributors {
            guard let dlStep = step as? DeepLinkStep else { return .none }

            switch dlStep {
            case .screenA:
                return navigateToScreen(.a)
            case .screenB:
                return navigateToScreen(.b)
            case .screenC:
                return navigateToScreen(.c)
            case .screenD:
                return navigateToScreen(.d)
            case .screenE:
                return navigateToScreen(.e)
            case let .deepLink(screen):
                return deepLink(to: screen)
            }
        }

        private func navigateToScreen(_ screen: DeepLinkStep.Screen) -> FlowContributors {
            let vc = DeepLinkViewController()
            vc.screenIdentifier = screen.rawValue
            navigationController.pushViewController(vc, animated: false)
            return .none
        }

        private func deepLink(to screen: DeepLinkStep.Screen) -> FlowContributors {
            // Root로 돌아간 후 해당 화면까지 순차 push
            navigationController.popToRootViewController(animated: false)

            let allScreens = DeepLinkStep.Screen.allCases
            guard let targetIndex = allScreens.firstIndex(of: screen) else { return .none }

            // A는 이미 root이므로, target이 A면 빈 배열
            if targetIndex == 0 {
                return .none
            }

            // A부터 target까지의 경로 (A 제외)
            let path = Array(allScreens[1 ... targetIndex])

            for targetScreen in path {
                let vc = DeepLinkViewController()
                vc.screenIdentifier = targetScreen.rawValue
                navigationController.pushViewController(vc, animated: false)
            }

            return .none
        }
    }

    final class DeepLinkViewController: UIViewController {
        var screenIdentifier: String = ""
    }

    // MARK: - Parent/Child Flow Tests

    enum ParentStep: Step, Equatable {
        case main
        case openChild
        case childCompleted
        case messageFromChild
    }

    enum ChildStep: Step, Equatable {
        case initial
        case next
        case end
    }

    @MainActor
    final class ParentFlow: Flow {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        var navigateCallCount = 0
        var childFlow: ChildFlow?
        var receivedMessageFromChild = false
        var childCompletedReceived = false

        func navigate(to step: Step) -> FlowContributors {
            navigateCallCount += 1

            if let parentStep = step as? ParentStep {
                switch parentStep {
                case .main:
                    return .none
                case .openChild:
                    let child = ChildFlow()
                    childFlow = child
                    let stepper = OneStepper(withSingleStep: ChildStep.initial)
                    return .one(flowContributor: .contribute(
                        withNextPresentable: child,
                        withNextStepper: stepper
                    ))
                case .childCompleted:
                    childCompletedReceived = true
                    return .none
                case .messageFromChild:
                    receivedMessageFromChild = true
                    return .none
                }
            }

            return .none
        }
    }

    @MainActor
    final class ChildFlow: Flow {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        private let steps = AsyncReplaySubject<Step>(bufferSize: 1)

        func navigate(to step: Step) -> FlowContributors {
            if let childStep = step as? ChildStep {
                switch childStep {
                case .initial:
                    return .none
                case .next:
                    return .none
                case .end:
                    return .end(forwardToParentFlowWithStep: ParentStep.childCompleted)
                }
            }
            return .none
        }

        func sendMessageToParent() {
            steps.send(ParentStep.messageFromChild)
        }

        func end() {
            steps.send(ChildStep.end)
        }
    }

    // MARK: - ForwardToCurrentFlow Test

    enum ForwardStep: Step, Equatable {
        case initial
        case triggerForward
        case forwarded
    }

    @MainActor
    final class ForwardingFlow: Flow {
        let rootPresentable = MockPresentable()
        var root: Presentable { rootPresentable }

        var navigateCallCount = 0
        var lastReceivedSteps: [Step] = []

        func navigate(to step: Step) -> FlowContributors {
            navigateCallCount += 1
            lastReceivedSteps.append(step)

            if let forwardStep = step as? ForwardStep {
                switch forwardStep {
                case .initial:
                    return .none
                case .triggerForward:
                    return .one(flowContributor: .forwardToCurrentFlow(withStep: ForwardStep.forwarded))
                case .forwarded:
                    return .none
                }
            }

            return .none
        }
    }

#endif
