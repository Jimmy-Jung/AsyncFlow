//
//  FlowCoordinatorTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
@testable import AsyncFlowExample
import Testing
import UIKit

@MainActor
@Suite("FlowCoordinator Tests")
struct FlowCoordinatorTests {
    // MARK: - Logger Integration Tests

    @Test("FlowCoordinator - Logger 연결 확인")
    func loggerIntegration() async throws {
        // Given
        let mockLogger = MockFlowLogger()
        let coordinator = FlowCoordinator(logger: mockLogger)
        let flow = TabAFlow()
        let stepper = OneStepper(withSingleStep: TabAStep.navigateToScreen1)

        // When
        coordinator.coordinate(flow: flow, with: stepper)

        // 약간의 딜레이 (비동기 처리 대기)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        // Then
        #expect(mockLogger.loggedStacks.count > 0)
    }

    @Test("FlowCoordinator - NavigationFlow에 onStackChanged 콜백 설정")
    func onStackChangedCallbackSetup() async throws {
        // Given
        let mockLogger = MockFlowLogger()
        let coordinator = FlowCoordinator(logger: mockLogger)
        let flow = TabAFlow()
        let stepper = OneStepper(withSingleStep: TabAStep.navigateToScreen1)

        // When
        coordinator.coordinate(flow: flow, with: stepper)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: 로거에 스택 정보가 기록되어야 함
        #expect(mockLogger.loggedStacks.count > 0)
    }

    @Test("FlowCoordinator - 자식 Flow에도 로깅 동작")
    func childFlowLogging() async throws {
        // Given
        let mockLogger = MockFlowLogger()
        let coordinator = FlowCoordinator(logger: mockLogger)
        let window = UIWindow(frame: .zero)
        let appFlow = AppFlow(window: window)
        let stepper = OneStepper(withSingleStep: AppStep.appDidStart)

        // When
        coordinator.coordinate(flow: appFlow, with: stepper)

        try await Task.sleep(nanoseconds: 300_000_000) // 0.3초

        // Then: 여러 Flow의 로그가 기록되어야 함
        #expect(mockLogger.loggedStacks.count > 0)
    }

    // MARK: - Navigation Event Tests

    @Test("FlowCoordinator - willNavigate 이벤트 발생")
    func willNavigateEvent() async throws {
        // Given
        let coordinator = FlowCoordinator()
        let flow = TabAFlow()
        let stepper = OneStepper(withSingleStep: TabAStep.navigateToScreen1)

        var receivedEvents: [NavigationEvent] = []

        // willNavigate 구독
        Task {
            for await event in coordinator.willNavigate {
                receivedEvents.append(event)
                if receivedEvents.count >= 1 { break }
            }
        }

        // When
        coordinator.coordinate(flow: flow, with: stepper)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(!receivedEvents.isEmpty)
    }

    @Test("FlowCoordinator - didNavigate 이벤트 발생")
    func didNavigateEvent() async throws {
        // Given
        let coordinator = FlowCoordinator()
        let flow = TabAFlow()
        let stepper = OneStepper(withSingleStep: TabAStep.navigateToScreen1)

        var receivedEvents: [NavigationEvent] = []

        // didNavigate 구독
        Task {
            for await event in coordinator.didNavigate {
                receivedEvents.append(event)
                if receivedEvents.count >= 1 { break }
            }
        }

        // When
        coordinator.coordinate(flow: flow, with: stepper)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(!receivedEvents.isEmpty)
    }

    // MARK: - Step Forwarding Tests

    @Test("FlowCoordinator - AppStep이 자식 Flow로 전달")
    func appStepForwarding() async throws {
        // Given
        let mockLogger = MockFlowLogger()
        let coordinator = FlowCoordinator(logger: mockLogger)
        let window = UIWindow(frame: .zero)
        let appFlow = AppFlow(window: window)
        let stepper = OneStepper(withSingleStep: AppStep.appDidStart)

        coordinator.coordinate(flow: appFlow, with: stepper)

        try await Task.sleep(nanoseconds: 200_000_000)

        // When: 크로스 탭 네비게이션
        coordinator.navigate(to: AppStep.switchToTabBScreen3)

        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: TabBFlow로 전달되어 로그가 기록되어야 함
        let tabBLogs = mockLogger.loggedStacks.filter { $0.flowName.contains("TabBFlow") }
        #expect(!tabBLogs.isEmpty)
    }
}

// MARK: - Mock Logger

@MainActor
final class MockFlowLogger: FlowLogger {
    var loggedStacks: [NavigationStack] = []

    func log(navigationStack: NavigationStack) {
        loggedStacks.append(navigationStack)
    }
}
