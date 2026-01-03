//
//  NavigationFlowTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
@testable import AsyncFlowExample
import Testing
import UIKit

@MainActor
@Suite("NavigationFlow Core Tests")
struct NavigationFlowTests {
    // MARK: - Delegate Tests

    @Test("NavigationFlow - Delegate가 strong reference로 유지됨")
    func delegateRetention() async throws {
        // Given
        let flow = TabAFlow()

        // When
        _ = flow.navigate(to: TabAStep.navigateToScreen1)

        // Then: delegate가 nil이 아니어야 함
        #expect(flow.navigationController.delegate != nil)
    }

    @Test("NavigationFlow - 시스템 뒤로가기 시뮬레이션")
    func systemBackNavigation() async throws {
        // Given
        let flow = TabAFlow()
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)

        #expect(flow.navigationController.viewControllers.count == 3)

        // When: 시스템 pop 시뮬레이션 (animated: false)
        flow.navigationController.popViewController(animated: false)

        // Then
        #expect(flow.navigationController.viewControllers.count == 2)
        #expect(flow.navigationController.topViewController is A_2ViewController)
    }

    // MARK: - Associated Objects Tests

    @Test("NavigationFlow - Step 연결 확인")
    func stepAssociation() async throws {
        // Given
        let flow = TabAFlow()

        // When
        _ = flow.navigate(to: TabAStep.navigateToScreen1)

        // Then
        let vc = flow.navigationController.viewControllers.first
        let associatedStep = flow.associatedStep(for: vc!)
        #expect(associatedStep != nil)
    }

    @Test("NavigationFlow - Stepper 연결 확인")
    func stepperAssociation() async throws {
        // Given
        let flow = TabAFlow()

        // When
        _ = flow.navigate(to: TabAStep.navigateToScreen1)

        // Then
        let vc = flow.navigationController.viewControllers.first
        let associatedStepper = flow.associatedStepper(for: vc!)
        #expect(associatedStepper != nil)
        #expect(associatedStepper is A_1ViewModel)
    }

    @Test("NavigationFlow - 모든 ViewController에 Step/Stepper 연결 확인")
    func allViewControllersHaveAssociations() async throws {
        // Given
        let flow = TabAFlow()

        // When: 여러 화면 push
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)

        // Then: 모든 VC가 Step과 Stepper를 가져야 함
        for vc in flow.navigationController.viewControllers {
            #expect(flow.associatedStep(for: vc) != nil)
            #expect(flow.associatedStepper(for: vc) != nil)
        }
    }

    // MARK: - Metadata Tests

    @Test("NavigationFlow - currentStackMetadata 정확성")
    func testCurrentStackMetadata() async throws {
        // Given
        let flow = TabAFlow()

        // When
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)

        // Then
        let metadata = flow.currentStackMetadata
        #expect(metadata.count == 3)
        #expect(metadata[0].displayName == "A-1")
        #expect(metadata[1].displayName == "A-2")
        #expect(metadata[2].displayName == "A-3")
    }

    @Test("NavigationFlow - currentStackPath 생성")
    func testCurrentStackPath() async throws {
        // Given
        let flow = TabAFlow()

        // When
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)

        // Then
        let stackPath = flow.currentStackPath
        #expect(stackPath == "A-1 → A-2 → A-3")
    }

    @Test("NavigationFlow - 빈 스택의 currentStackPath")
    func emptyStackPath() async throws {
        // Given
        let flow = TabAFlow()

        // When & Then
        let stackPath = flow.currentStackPath
        #expect(stackPath.isEmpty)
    }

    @Test("NavigationFlow - Pop 후 metadata 업데이트")
    func metadataAfterPop() async throws {
        // Given
        let flow = TabAFlow()
        flow.animated = false
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)

        // When: Pop
        _ = flow.navigate(to: TabAStep.popViewController(count: 1))

        // Then
        let metadata = flow.currentStackMetadata
        #expect(metadata.count == 2)
        #expect(metadata[0].displayName == "A-1")
        #expect(metadata[1].displayName == "A-2")

        let stackPath = flow.currentStackPath
        #expect(stackPath == "A-1 → A-2")
    }

    // MARK: - UIViewController Extension Tests

    @Test("UIViewController - navigationStackPath extension")
    func navigationStackPathExtension() async throws {
        // Given
        let flow = TabAFlow()
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)

        // When
        let topVC = flow.navigationController.topViewController
        let stackPath = topVC?.navigationStackPath

        // Then
        #expect(stackPath == "A-1 → A-2")
    }

    // MARK: - Edge Cases

    @Test("NavigationFlow - 동일 화면 연속 push")
    func pushingSameScreenMultipleTimes() async throws {
        // Given
        let flow = TabAFlow()

        // When: A-1을 3번 push
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen1)

        // Then: 3개의 인스턴스가 생성되어야 함
        #expect(flow.navigationController.viewControllers.count == 3)
        #expect(flow.navigationController.viewControllers.allSatisfy { $0 is A_1ViewController })

        // 각각 다른 인스턴스여야 함
        let vc1 = flow.navigationController.viewControllers[0]
        let vc2 = flow.navigationController.viewControllers[1]
        let vc3 = flow.navigationController.viewControllers[2]
        #expect(vc1 !== vc2)
        #expect(vc2 !== vc3)
    }

    @Test("NavigationFlow - Pop count가 스택보다 큰 경우")
    func popCountExceedsStack() async throws {
        // Given
        let flow = TabAFlow()
        flow.animated = false
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)

        // When: 스택(2개)보다 많이 pop 시도 (10개)
        _ = flow.navigate(to: TabAStep.popViewController(count: 10))

        // Then: Root만 남아야 함
        #expect(flow.navigationController.viewControllers.count == 1)
        #expect(flow.navigationController.topViewController is A_1ViewController)
    }

    @Test("NavigationFlow - Root에서 popToRoot 호출")
    func popToRootWhenAlreadyAtRoot() async throws {
        // Given
        let flow = TabAFlow()
        _ = flow.navigate(to: TabAStep.navigateToScreen1)

        // When: Root에서 popToRoot
        _ = flow.navigate(to: TabAStep.popToRoot)

        // Then: 여전히 Root
        #expect(flow.navigationController.viewControllers.count == 1)
        #expect(flow.navigationController.topViewController is A_1ViewController)
    }

    @Test("NavigationFlow - 빈 스택에서 pop 시도")
    func popFromEmptyStack() async throws {
        // Given
        let flow = TabAFlow()

        // When: 빈 스택에서 pop
        _ = flow.navigate(to: TabAStep.popViewController(count: 1))

        // Then: 스택은 여전히 비어있어야 함
        #expect(flow.navigationController.viewControllers.isEmpty)
    }
}
