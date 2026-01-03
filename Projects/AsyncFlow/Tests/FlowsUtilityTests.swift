//
//  FlowsUtilityTests.swift
//  AsyncFlowTests
//
//  Created by jimmy on 2026. 1. 1.
//

@testable import AsyncFlow
import Foundation
import Testing

#if canImport(UIKit)
    import UIKit

    @Suite("Flows Utility Tests")
    struct FlowsUtilityTests {
        // MARK: - Basic Use Tests

        @Test("Use single flow with created strategy")
        @MainActor
        func useSingleFlowCreated() async {
            // Given
            let flow = TestUIFlow()
            var blockCalled = false

            // When
            Flows.use(flow, when: .created) { (root: UINavigationController) in
                blockCalled = true
                #expect(root === flow.navigationController)
            }

            // Then - .created는 즉시 실행
            #expect(blockCalled)
        }

        @Test("Use single flow with ready strategy")
        @MainActor
        func useSingleFlowReady() async {
            // Given
            let flow = TestUIFlow()
            var blockCalled = false

            // When
            Flows.use(flow, when: .ready) { (root: UINavigationController) in
                blockCalled = true
                #expect(root === flow.navigationController)
            }

            // Then - ready 대기 중
            #expect(!blockCalled)

            // Flow가 ready되면 호출됨
            Task { @MainActor in
                flow.flowReadySubject.send(true)
            }

            await Test.waitUntil(timeout: 2.0) { blockCalled }

            #expect(blockCalled)
        }

        @Test("Use single flow waits until ready")
        @MainActor
        func useSingleFlowWaitsReady() async {
            // Given
            let flow = TestUIFlow()
            var blockExecuted = false

            // When
            Flows.use(flow, when: .ready) { (_: UINavigationController) in
                blockExecuted = true
            }

            try? await Task.sleep(nanoseconds: 50_000_000)
            #expect(!blockExecuted)

            flow.flowReadySubject.send(true)
            await Test.waitUntil { blockExecuted }

            // Then
            #expect(blockExecuted)
        }

        // MARK: - Multiple Flows Tests

        @Test("Use two flows with created strategy")
        @MainActor
        func useTwoFlowsCreated() async {
            // Given
            let flow1 = TestUIFlow()
            let flow2 = TestUIFlow()
            var blockCalled = false

            // When
            Flows.use(flow1, flow2, when: .created) {
                (root1: UINavigationController, root2: UINavigationController) in
                blockCalled = true
                #expect(root1 === flow1.navigationController)
                #expect(root2 === flow2.navigationController)
            }

            // Then
            #expect(blockCalled)
        }

        @Test("Use two flows with ready strategy")
        @MainActor
        func useTwoFlowsReady() async {
            // Given
            let flow1 = TestUIFlow()
            let flow2 = TestUIFlow()
            var blockCalled = false

            // When
            Flows.use(flow1, flow2, when: .ready) {
                (_: UINavigationController, _: UINavigationController) in
                blockCalled = true
            }

            #expect(!blockCalled)

            // Ready 신호를 비동기로 전송
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 10_000_000)
                flow1.flowReadySubject.send(true)
                try? await Task.sleep(nanoseconds: 10_000_000)
                flow2.flowReadySubject.send(true)
            }

            await Test.waitUntil(timeout: 3.0) { blockCalled }

            // Then
            #expect(blockCalled)
        }

        @Test("Use three flows")
        @MainActor
        func useThreeFlows() async {
            // Given
            let flow1 = TestUIFlow()
            let flow2 = TestUIFlow()
            let flow3 = TestUIFlow()
            var blockCalled = false

            // When
            Flows.use(flow1, flow2, flow3, when: .ready) {
                (_: UINavigationController, _: UINavigationController, _: UINavigationController) in
                blockCalled = true
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 10_000_000)
                flow1.flowReadySubject.send(true)
                try? await Task.sleep(nanoseconds: 10_000_000)
                flow2.flowReadySubject.send(true)
                try? await Task.sleep(nanoseconds: 10_000_000)
                flow3.flowReadySubject.send(true)
            }

            await Test.waitUntil(timeout: 3.0) { blockCalled }

            // Then
            #expect(blockCalled)
        }

        @Test("Use four flows")
        @MainActor
        func useFourFlows() async {
            // Given
            let flow1 = TestUIFlow()
            let flow2 = TestUIFlow()
            let flow3 = TestUIFlow()
            let flow4 = TestUIFlow()
            var blockCalled = false

            // When
            Flows.use(flow1, flow2, flow3, flow4, when: .ready) {
                (_: UINavigationController, _: UINavigationController, _: UINavigationController, _: UINavigationController) in
                blockCalled = true
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 10_000_000)
                flow1.flowReadySubject.send(true)
                flow2.flowReadySubject.send(true)
                flow3.flowReadySubject.send(true)
                flow4.flowReadySubject.send(true)
            }

            await Test.waitUntil(timeout: 3.0) { blockCalled }

            // Then
            #expect(blockCalled)
        }

        @Test("Use five flows")
        @MainActor
        func useFiveFlows() async {
            // Given
            let flow1 = TestUIFlow()
            let flow2 = TestUIFlow()
            let flow3 = TestUIFlow()
            let flow4 = TestUIFlow()
            let flow5 = TestUIFlow()
            var blockCalled = false

            // When
            Flows.use(flow1, flow2, flow3, flow4, flow5, when: .ready) {
                (_: UINavigationController, _: UINavigationController, _: UINavigationController, _: UINavigationController, _: UINavigationController) in
                blockCalled = true
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 10_000_000)
                flow1.flowReadySubject.send(true)
                flow2.flowReadySubject.send(true)
                flow3.flowReadySubject.send(true)
                flow4.flowReadySubject.send(true)
                flow5.flowReadySubject.send(true)
            }

            await Test.waitUntil(timeout: 3.0) { blockCalled }

            // Then
            #expect(blockCalled)
        }

        @Test("Use flows array")
        @MainActor
        func useFlowsArray() async {
            // Given
            let flow1 = TestUIFlow()
            let flow2 = TestUIFlow()
            let flow3 = TestUIFlow()
            let flows = [flow1, flow2, flow3]
            var blockCalled = false

            // When
            Flows.use(flows, when: .created) { (roots: [UINavigationController]) in
                blockCalled = true
                #expect(roots.count == 3)
            }

            // Then
            #expect(blockCalled)
        }

        @Test("Use flows array with ready strategy")
        @MainActor
        func useFlowsArrayReady() async {
            // Given
            let flow1 = TestUIFlow()
            let flow2 = TestUIFlow()
            let flows = [flow1, flow2]
            var blockCalled = false

            // When
            Flows.use(flows, when: .ready) { (_: [UINavigationController]) in
                blockCalled = true
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 10_000_000)
                flow1.flowReadySubject.send(true)
                try? await Task.sleep(nanoseconds: 10_000_000)
                flow2.flowReadySubject.send(true)
            }

            await Test.waitUntil(timeout: 3.0) { blockCalled }

            // Then
            #expect(blockCalled)
        }

        // MARK: - Real-world Scenarios

        @Test("TabBar setup with three flows")
        @MainActor
        func tabBarSetupWithThreeFlows() async {
            // Given
            let homeFlow = TestUIFlow()
            let searchFlow = TestUIFlow()
            let profileFlow = TestUIFlow()

            let tabBarController = UITabBarController()
            var setupCompleted = false

            // When
            Flows.use(homeFlow, searchFlow, profileFlow, when: .created) {
                (home: UINavigationController, search: UINavigationController, profile: UINavigationController) in
                tabBarController.viewControllers = [home, search, profile]
                setupCompleted = true
            }

            // Then
            #expect(setupCompleted)
            #expect(tabBarController.viewControllers?.count == 3)
        }

        @Test("Modal flow presentation")
        @MainActor
        func modalFlowPresentation() async {
            // Given
            _ = UIViewController()
            let modalFlow = TestUIFlow()
            var presented = false

            // When
            Flows.use(modalFlow, when: .created) { (_: UINavigationController) in
                // 실제로는 parentVC.present(root, animated: true)
                presented = true
            }

            // Then
            #expect(presented)
        }

        @Test("Sequential flow setup")
        @MainActor
        func sequentialFlowSetup() async {
            // Given
            let flow1 = TestUIFlow()
            let flow2 = TestUIFlow()
            var flow1Setup = false
            var flow2Setup = false

            // When
            Flows.use(flow1, when: .ready) { (_: UINavigationController) in
                flow1Setup = true
            }

            Flows.use(flow2, when: .ready) { (_: UINavigationController) in
                flow2Setup = true
            }

            Task { @MainActor in
                flow1.flowReadySubject.send(true)
                flow2.flowReadySubject.send(true)
            }

            await Test.waitUntil(timeout: 2.0) { flow1Setup && flow2Setup }

            // Then
            #expect(flow1Setup)
            #expect(flow2Setup)
        }

        // MARK: - Edge Cases

        @Test("Use flow that never becomes ready")
        @MainActor
        func flowNeverBecomesReady() async {
            // Given
            let flow = TestUIFlow()
            var blockCalled = false

            // When
            Flows.use(flow, when: .ready) { (_: UINavigationController) in
                blockCalled = true
            }

            try? await Task.sleep(nanoseconds: 100_000_000)

            // Then
            #expect(!blockCalled)
        }

        @Test("Use flow with false ready signal")
        @MainActor
        func flowWithFalseReadySignal() async {
            // Given
            let flow = TestUIFlow()
            var blockCalled = false

            // When
            Flows.use(flow, when: .ready) { (_: UINavigationController) in
                blockCalled = true
            }

            flow.flowReadySubject.send(false)
            try? await Task.sleep(nanoseconds: 50_000_000)

            #expect(!blockCalled)

            flow.flowReadySubject.send(true)
            await Test.waitUntil { blockCalled }

            // Then
            #expect(blockCalled)
        }

        @Test("Use empty flows array")
        @MainActor
        func useEmptyFlowsArray() async {
            // Given
            let flows: [TestUIFlow] = []
            var blockCalled = false

            // When
            Flows.use(flows, when: .created) { (roots: [UINavigationController]) in
                blockCalled = true
                #expect(roots.isEmpty)
            }

            // Then
            #expect(blockCalled)
        }
    }

    // MARK: - Test Flow

    @MainActor
    final class TestUIFlow: Flow {
        let navigationController = UINavigationController()
        var root: Presentable { navigationController }

        func navigate(to _: Step) -> FlowContributors {
            .none
        }
    }

#endif
