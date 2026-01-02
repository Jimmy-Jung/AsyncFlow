//
//  MainFlowTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 2.
//

// swiftlint:disable file_length

@testable import AsyncFlow
@testable import AsyncFlowExample
import Foundation
import Testing
import UIKit

// MARK: - MainFlow Unit Tests

@Suite("MainFlow 단위 테스트", .tags(.flow, .unit, .navigation))
struct MainFlowTests {
    // MARK: - Initialization Tests

    @Test("MainFlow 초기화 시 NavigationController 생성")
    @MainActor
    func initialization() async throws {
        // Given & When
        let mainFlow = MainFlow()

        // Then
        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.isEmpty)
        #expect(navController.navigationBar.prefersLargeTitles == true)
    }

    // MARK: - Screen Navigation Tests

    @Test("Screen A 네비게이션 시 ViewController 생성")
    @MainActor
    func navigateToScreenA() async throws {
        // Given
        let mainFlow = MainFlow()

        // When
        let contributors = mainFlow.navigate(to: DemoStep.screenA)

        // Then
        if case .one = contributors {
            // 하나의 contributor가 반환됨
        } else {
            Issue.record("Expected .one contributor")
        }

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 1)

        let firstVC = try #require(navController.viewControllers.first as? ScreenViewController)
        #expect(firstVC.viewModel.state.config.screen == .a)
    }

    @Test("Screen B 네비게이션 시 스택에 추가")
    @MainActor
    func navigateToScreenB() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)

        // When
        let contributors = mainFlow.navigate(to: DemoStep.screenB)

        // Then
        if case .one = contributors {
            // 하나의 contributor가 반환됨
        } else {
            Issue.record("Expected .one contributor")
        }

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 2)

        let secondVC = try #require(navController.viewControllers[1] as? ScreenViewController)
        #expect(secondVC.viewModel.state.config.screen == .b)
    }

    @Test("순차 네비게이션 (A → B → C)", arguments: [
        [DemoStep.screenA, DemoStep.screenB, DemoStep.screenC],
    ])
    @MainActor
    func sequentialNavigation(steps: [DemoStep]) async throws {
        // Given
        let mainFlow = MainFlow()

        // When
        for step in steps {
            _ = mainFlow.navigate(to: step)
        }

        // Then
        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == steps.count)

        let expectedScreens: [DemoStep.Screen] = [.a, .b, .c]
        Test.expectNavigationStack(navController, matches: expectedScreens)
    }

    @Test("모든 화면 순차 네비게이션 (A → E)")
    @MainActor
    func fullNavigation() async throws {
        // Given
        let mainFlow = MainFlow()
        let allSteps: [DemoStep] = [.screenA, .screenB, .screenC, .screenD, .screenE]

        // When
        for step in allSteps {
            _ = mainFlow.navigate(to: step)
        }

        // Then
        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 5)

        Test.expectNavigationStack(navController, matches: [.a, .b, .c, .d, .e])
    }

    // MARK: - Back Navigation Tests

    @Test("1단계 뒤로 가기 (C → B)")
    @MainActor
    func testGoBack() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)
        _ = mainFlow.navigate(to: DemoStep.screenB)
        _ = mainFlow.navigate(to: DemoStep.screenC)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 3)

        // When
        _ = mainFlow.navigate(to: DemoStep.goBack)

        // 스택이 실제로 변경될 때까지 대기
        await Test.waitUntil { navController.viewControllers.count == 2 }

        // Then
        #expect(navController.viewControllers.count == 2)
        Test.expectNavigationStack(navController, matches: [.a, .b])
    }

    @Test("2단계 뒤로 가기 (C → A)")
    @MainActor
    func testGoBack2() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)
        _ = mainFlow.navigate(to: DemoStep.screenB)
        _ = mainFlow.navigate(to: DemoStep.screenC)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 3)

        // When
        _ = mainFlow.navigate(to: DemoStep.goBack2)

        // 스택이 실제로 변경될 때까지 대기
        await Test.waitUntil { navController.viewControllers.count == 1 }

        // Then
        #expect(navController.viewControllers.count == 1)
        Test.expectNavigationStack(navController, matches: [.a])
    }

    @Test("3단계 뒤로 가기 (D → A)")
    @MainActor
    func testGoBack3() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)
        _ = mainFlow.navigate(to: DemoStep.screenB)
        _ = mainFlow.navigate(to: DemoStep.screenC)
        _ = mainFlow.navigate(to: DemoStep.screenD)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 4)

        // When
        _ = mainFlow.navigate(to: DemoStep.goBack3)

        // 스택이 실제로 변경될 때까지 대기
        await Test.waitUntil { navController.viewControllers.count == 1 }

        // Then
        #expect(navController.viewControllers.count == 1)
        Test.expectNavigationStack(navController, matches: [.a])
    }

    @Test("루트로 이동")
    @MainActor
    func testGoToRoot() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)
        _ = mainFlow.navigate(to: DemoStep.screenB)
        _ = mainFlow.navigate(to: DemoStep.screenC)
        _ = mainFlow.navigate(to: DemoStep.screenD)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 4)

        // When
        _ = mainFlow.navigate(to: DemoStep.goToRoot)

        // 스택이 실제로 변경될 때까지 대기
        await Test.waitUntil { navController.viewControllers.count == 1 }

        // Then
        #expect(navController.viewControllers.count == 1)
        Test.expectNavigationStack(navController, matches: [.a])
    }

    // MARK: - Jump Navigation Tests

    @Test("기존 화면으로 점프 (A → B → C → B)")
    @MainActor
    func goToSpecificExistingScreen() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)
        _ = mainFlow.navigate(to: DemoStep.screenB)
        _ = mainFlow.navigate(to: DemoStep.screenC)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 3)

        // When - Screen B로 점프 (스택에 이미 존재)
        _ = mainFlow.navigate(to: DemoStep.goToSpecific(.b))

        // 스택이 실제로 변경될 때까지 대기
        await Test.waitUntil { navController.viewControllers.count == 2 }

        // Then - Screen B까지만 남김
        #expect(navController.viewControllers.count == 2)
        Test.expectNavigationStack(navController, matches: [.a, .b])
    }

    @Test("새 화면으로 점프 (A → B → D)")
    @MainActor
    func goToSpecificNewScreen() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)
        _ = mainFlow.navigate(to: DemoStep.screenB)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 2)

        // When - Screen D로 점프 (스택에 없음)
        _ = mainFlow.navigate(to: DemoStep.goToSpecific(.d))

        // Then - Screen D가 추가됨
        #expect(navController.viewControllers.count == 3)
        Test.expectNavigationStack(navController, matches: [.a, .b, .d])
    }

    // MARK: - DeepLink Tests

    @Test("DeepLink: Screen B로 이동 (A → B)")
    @MainActor
    func deepLinkToB() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)
        _ = mainFlow.navigate(to: DemoStep.screenC)
        _ = mainFlow.navigate(to: DemoStep.screenD)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 3)

        // When - DeepLink to B
        _ = mainFlow.navigate(to: DemoStep.deepLink(.b))

        // Then - Root로 돌아간 후 A → B 경로 생성
        await Test.waitUntil { navController.viewControllers.count == 2 }
        #expect(navController.viewControllers.count == 2)
        Test.expectNavigationStack(navController, matches: [.a, .b])
    }

    @Test("DeepLink: Screen C로 이동 (A → B → C)")
    @MainActor
    func deepLinkToC() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)
        _ = mainFlow.navigate(to: DemoStep.screenD)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)

        // When - DeepLink to C
        _ = mainFlow.navigate(to: DemoStep.deepLink(.c))

        // Then - A → B → C 경로 생성
        await Test.waitUntil { navController.viewControllers.count == 3 }
        #expect(navController.viewControllers.count == 3)
        Test.expectNavigationStack(navController, matches: [.a, .b, .c])
    }

    @Test("DeepLink: Screen A로 이동 (이미 Root)")
    @MainActor
    func deepLinkToA() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)
        _ = mainFlow.navigate(to: DemoStep.screenB)
        _ = mainFlow.navigate(to: DemoStep.screenC)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)

        // When - DeepLink to A
        _ = mainFlow.navigate(to: DemoStep.deepLink(.a))

        // Then - Root만 남음
        await Test.waitUntil { navController.viewControllers.count == 1 }
        #expect(navController.viewControllers.count == 1)
        Test.expectNavigationStack(navController, matches: [.a])
    }

    @Test("DeepLink: Screen E로 이동 (A → B → C → D → E)")
    @MainActor
    func deepLinkToE() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)
        _ = mainFlow.navigate(to: DemoStep.screenB)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)

        // When - DeepLink to E (최대 깊이)
        _ = mainFlow.navigate(to: DemoStep.deepLink(.e))

        // Then - A → B → C → D → E 전체 경로 생성
        await Test.waitUntil { navController.viewControllers.count == 5 }
        #expect(navController.viewControllers.count == 5)
        Test.expectNavigationStack(navController, matches: [.a, .b, .c, .d, .e])
    }

    // MARK: - Edge Cases

    @Test("Root에서 뒤로 가기 시도 (무시)")
    @MainActor
    func goBackFromRoot() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        #expect(navController.viewControllers.count == 1)

        // When
        _ = mainFlow.navigate(to: DemoStep.goBack)

        // Then - 변경 없음
        #expect(navController.viewControllers.count == 1)
        Test.expectNavigationStack(navController, matches: [.a])
    }

    @Test("스택 깊이 계산 검증")
    @MainActor
    func depthCalculation() async throws {
        // Given
        let mainFlow = MainFlow()

        // When & Then
        _ = mainFlow.navigate(to: DemoStep.screenA)
        var navController = try #require(mainFlow.root.viewController as? UINavigationController)
        var lastVC = try #require(navController.viewControllers.last as? ScreenViewController)
        #expect(lastVC.viewModel.state.stackInfo.contains("Depth: 0"))

        _ = mainFlow.navigate(to: DemoStep.screenB)
        navController = try #require(mainFlow.root.viewController as? UINavigationController)
        lastVC = try #require(navController.viewControllers.last as? ScreenViewController)
        #expect(lastVC.viewModel.state.stackInfo.contains("Depth: 1"))

        _ = mainFlow.navigate(to: DemoStep.screenC)
        navController = try #require(mainFlow.root.viewController as? UINavigationController)
        lastVC = try #require(navController.viewControllers.last as? ScreenViewController)
        #expect(lastVC.viewModel.state.stackInfo.contains("Depth: 2"))
    }

    @Test("알 수 없는 Step 처리")
    @MainActor
    func unknownStep() async throws {
        // Given
        let mainFlow = MainFlow()
        _ = mainFlow.navigate(to: DemoStep.screenA)

        let navController = try #require(mainFlow.root.viewController as? UINavigationController)
        let initialCount = navController.viewControllers.count

        // When - 알 수 없는 Step (NoneStep)
        let contributors = mainFlow.navigate(to: NoneStep())

        // Then - 아무 일도 일어나지 않음
        if case .none = contributors {
            // .none이 반환됨
        } else {
            Issue.record("Expected .none contributors")
        }
        #expect(navController.viewControllers.count == initialCount)
    }
}
