//
//  DemoStepTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
@testable import AsyncFlowExample
import Testing

@Suite("Demo Step Tests")
struct DemoStepTests {
    @Test("AppStep - Equatable 확인")
    func appStepEquatable() {
        // Given
        let step1 = AppStep.appDidStart
        let step2 = AppStep.appDidStart
        let step3 = AppStep.switchToTabAScreen1

        // Then
        #expect(step1 == step2)
        #expect(step1 != step3)
    }

    @Test("TabAStep - Equatable with associated values")
    func tabAStepEquatable() {
        // Given
        let step1 = TabAStep.popViewController(count: 1)
        let step2 = TabAStep.popViewController(count: 1)
        let step3 = TabAStep.popViewController(count: 2)

        // Then
        #expect(step1 == step2)
        #expect(step1 != step3)
    }

    @Test("TabBStep - 모든 케이스 확인")
    func tabBStepAllCases() {
        // Given
        let navigationSteps: [TabBStep] = [
            .navigateToScreen1,
            .navigateToScreen2,
            .navigateToScreen3,
            .navigateToScreen4,
            .navigateToScreen5,
        ]

        let actionSteps: [TabBStep] = [
            .popViewController(),
            .popViewController(count: 2),
            .popToRoot,
        ]

        // Then: 모두 다른 Step이어야 함
        #expect(Set(navigationSteps.map { String(describing: $0) }).count == 5)
        #expect(actionSteps.count == 3)
    }

    @Test("ModalStep - Equatable 확인")
    func modalStepEquatable() {
        // Given
        let step1 = ModalStep.presentModal
        let step2 = ModalStep.presentModal
        let step3 = ModalStep.dismissModal

        // Then
        #expect(step1 == step2)
        #expect(step1 != step3)
    }
}
