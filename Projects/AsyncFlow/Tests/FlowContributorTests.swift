//
//  FlowContributorTests.swift
//  AsyncFlowTests
//
//  Created by jimmy on 2026. 1. 1.
//

@testable import AsyncFlow
import Foundation
import Testing

@Suite("FlowContributor Tests")
struct FlowContributorTests {
    // MARK: - Basic Contributor Tests

    @Test("Contribute with separate Presentable and Stepper")
    @MainActor
    func contributeWithSeparateComponents() {
        // Given
        let presentable = MockPresentable()
        let stepper = MockStepper()

        // When
        let contributor = FlowContributor.contribute(
            withNextPresentable: presentable,
            withNextStepper: stepper
        )

        // Then
        switch contributor {
        case .contribute:
            #expect(true)
        default:
            #expect(Bool(false), "Should be contribute case")
        }
    }

    @Test("Contribute with combined Presentable & Stepper")
    @MainActor
    func contributeWithCombinedComponent() {
        // Given
        let mockViewController = MockViewController()

        // When
        let contributor = FlowContributor.contribute(withNext: mockViewController)

        // Then
        switch contributor {
        case .contribute:
            #expect(true)
        default:
            #expect(Bool(false), "Should be contribute case")
        }
    }

    @Test("ForwardToCurrentFlow with Step")
    func forwardToCurrentFlow() {
        // Given
        let step = TestStep.next

        // When
        let contributor = FlowContributor.forwardToCurrentFlow(withStep: step)

        // Then
        switch contributor {
        case let .forwardToCurrentFlow(withStep: receivedStep):
            #expect((receivedStep as? TestStep) == step)
        default:
            #expect(Bool(false), "Should be forwardToCurrentFlow case")
        }
    }

    @Test("ForwardToParentFlow with Step")
    func forwardToParentFlow() {
        // Given
        let step = TestStep.end

        // When
        let contributor = FlowContributor.forwardToParentFlow(withStep: step)

        // Then
        switch contributor {
        case let .forwardToParentFlow(withStep: receivedStep):
            #expect((receivedStep as? TestStep) == step)
        default:
            #expect(Bool(false), "Should be forwardToParentFlow case")
        }
    }

    // MARK: - FlowContributors Tests

    @Test("FlowContributors.none")
    func flowContributorsNone() {
        // When
        let contributors = FlowContributors.none

        // Then
        switch contributors {
        case .none:
            #expect(true)
        default:
            #expect(Bool(false), "Should be none case")
        }
    }

    @Test("FlowContributors.one")
    @MainActor
    func flowContributorsOne() {
        // Given
        let presentable = MockPresentable()
        let stepper = MockStepper()
        let contributor = FlowContributor.contribute(
            withNextPresentable: presentable,
            withNextStepper: stepper
        )

        // When
        let contributors = FlowContributors.one(flowContributor: contributor)

        // Then
        switch contributors {
        case .one:
            #expect(true)
        default:
            #expect(Bool(false), "Should be one case")
        }
    }

    @Test("FlowContributors.multiple with array")
    @MainActor
    func flowContributorsMultipleArray() {
        // Given
        let contributor1 = FlowContributor.contribute(
            withNextPresentable: MockPresentable(),
            withNextStepper: MockStepper()
        )
        let contributor2 = FlowContributor.contribute(
            withNextPresentable: MockPresentable(),
            withNextStepper: MockStepper()
        )

        // When
        let contributors = FlowContributors.multiple(flowContributors: [contributor1, contributor2])

        // Then
        switch contributors {
        case let .multiple(flowContributors):
            #expect(flowContributors.count == 2)
        default:
            #expect(Bool(false), "Should be multiple case")
        }
    }

    @Test("FlowContributors.multiple with variadic parameters")
    @MainActor
    func flowContributorsMultipleVariadic() {
        // Given
        let contributor1 = FlowContributor.contribute(
            withNextPresentable: MockPresentable(),
            withNextStepper: MockStepper()
        )
        let contributor2 = FlowContributor.contribute(
            withNextPresentable: MockPresentable(),
            withNextStepper: MockStepper()
        )
        let contributor3 = FlowContributor.contribute(
            withNextPresentable: MockPresentable(),
            withNextStepper: MockStepper()
        )

        // When
        let contributors = FlowContributors.multiple(contributor1, contributor2, contributor3)

        // Then
        switch contributors {
        case let .multiple(flowContributors):
            #expect(flowContributors.count == 3)
        default:
            #expect(Bool(false), "Should be multiple case")
        }
    }

    @Test("FlowContributors.end with Step")
    func flowContributorsEnd() {
        // Given
        let step = TestStep.end

        // When
        let contributors = FlowContributors.end(forwardToParentFlowWithStep: step)

        // Then
        switch contributors {
        case let .end(forwardToParentFlowWithStep: receivedStep):
            #expect((receivedStep as? TestStep) == step)
        default:
            #expect(Bool(false), "Should be end case")
        }
    }

    // MARK: - Edge Cases

    @Test("Empty multiple contributors")
    @MainActor
    func emptyMultipleContributors() {
        // When
        let contributors = FlowContributors.multiple(flowContributors: [])

        // Then
        switch contributors {
        case let .multiple(flowContributors):
            #expect(flowContributors.isEmpty)
        default:
            #expect(Bool(false), "Should be multiple case")
        }
    }

    @Test("AllowStepWhenNotPresented flag")
    @MainActor
    func allowStepWhenNotPresented() {
        // Given
        let presentable = MockPresentable()
        let stepper = MockStepper()

        // When
        let contributor = FlowContributor.contribute(
            withNextPresentable: presentable,
            withNextStepper: stepper,
            allowStepWhenNotPresented: true
        )

        // Then
        switch contributor {
        case let .contribute(_, _, allowNotPresented, _):
            #expect(allowNotPresented == true)
        default:
            #expect(Bool(false), "Should be contribute case")
        }
    }

    @Test("AllowStepWhenDismissed flag")
    @MainActor
    func allowStepWhenDismissed() {
        // Given
        let presentable = MockPresentable()
        let stepper = MockStepper()

        // When
        let contributor = FlowContributor.contribute(
            withNextPresentable: presentable,
            withNextStepper: stepper,
            allowStepWhenDismissed: true
        )

        // Then
        switch contributor {
        case let .contribute(_, _, _, allowDismissed):
            #expect(allowDismissed == true)
        default:
            #expect(Bool(false), "Should be contribute case")
        }
    }

    @Test("Both allow flags set")
    @MainActor
    func bothAllowFlags() {
        // Given
        let presentable = MockPresentable()
        let stepper = MockStepper()

        // When
        let contributor = FlowContributor.contribute(
            withNextPresentable: presentable,
            withNextStepper: stepper,
            allowStepWhenNotPresented: true,
            allowStepWhenDismissed: true
        )

        // Then
        switch contributor {
        case let .contribute(_, _, allowNotPresented, allowDismissed):
            #expect(allowNotPresented == true)
            #expect(allowDismissed == true)
        default:
            #expect(Bool(false), "Should be contribute case")
        }
    }
}

// MARK: - Mock ViewController

@MainActor
final class MockViewController: PlatformViewController, FlowStepper {
    let steps = AsyncReplaySubject<Step>(bufferSize: 1)

    var initialStep: Step {
        NoneStep()
    }
}
