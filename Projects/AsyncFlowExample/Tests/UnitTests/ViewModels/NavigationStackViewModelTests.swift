//
//  NavigationStackViewModelTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 2.
//

@testable import AsyncFlow
@testable import AsyncFlowExample
import Combine
import Foundation
import Testing

// MARK: - NavigationStackViewModel Unit Tests

@Suite("NavigationStackViewModel 단위 테스트", .tags(.viewModel, .unit, .navigation))
struct NavigationStackViewModelTests {
    // MARK: - Initialization Tests

    @Test("초기 스택 상태 검증")
    @MainActor
    func initialStack() async throws {
        // Given & When
        let viewModel = NavigationStackViewModel() // 독립 인스턴스 생성

        // Then
        #expect(viewModel.stack == [.a])
    }

    @Test("고정 높이 확인")
    @MainActor
    func testFixedHeight() async throws {
        // Then
        #expect(NavigationStackViewModel.fixedHeight == 180)
    }

    // MARK: - Update Current Screen Tests

    @Test("새 화면 Push 시 스택에 추가")
    @MainActor
    func updateCurrentScreenPush() async throws {
        // Given
        let viewModel = NavigationStackViewModel()
        #expect(viewModel.stack == [.a])

        // When
        viewModel.updateCurrentScreen(.b)

        // Then
        #expect(viewModel.stack == [.a, .b])

        // When
        viewModel.updateCurrentScreen(.c)

        // Then
        #expect(viewModel.stack == [.a, .b, .c])
    }

    @Test("기존 화면으로 Pop 시 스택 감소")
    @MainActor
    func updateCurrentScreenPop() async throws {
        // Given
        let viewModel = NavigationStackViewModel()
        viewModel.updateCurrentScreen(.b)
        viewModel.updateCurrentScreen(.c)
        viewModel.updateCurrentScreen(.d)

        #expect(viewModel.stack == [.a, .b, .c, .d])

        // When - Screen B로 Pop
        viewModel.updateCurrentScreen(.b)

        // Then - B 이후 화면들 제거
        #expect(viewModel.stack == [.a, .b])
    }

    @Test("순차 네비게이션 시 스택 추적", arguments: [
        [DemoStep.Screen.a, .b, .c],
        [DemoStep.Screen.a, .b, .c, .d, .e],
    ])
    @MainActor
    func sequentialNavigation(screens: [DemoStep.Screen]) async throws {
        // Given
        let viewModel = NavigationStackViewModel()

        // When
        for screen in screens.dropFirst() {
            viewModel.updateCurrentScreen(screen)
        }

        // Then
        #expect(viewModel.stack == screens)
    }

    // MARK: - Reset Tests

    @Test("루트로 초기화")
    @MainActor
    func testResetToRoot() async throws {
        // Given
        let viewModel = NavigationStackViewModel()
        viewModel.updateCurrentScreen(.b)
        viewModel.updateCurrentScreen(.c)
        viewModel.updateCurrentScreen(.d)

        #expect(viewModel.stack.count > 1)

        // When
        viewModel.resetToRoot()

        // Then
        #expect(viewModel.stack == [.a])
    }

    @Test("깊은 스택에서 루트로 초기화")
    @MainActor
    func resetFromDeepStack() async throws {
        // Given
        let viewModel = NavigationStackViewModel()
        let allScreens: [DemoStep.Screen] = [.a, .b, .c, .d, .e]
        for screen in allScreens.dropFirst() {
            viewModel.updateCurrentScreen(screen)
        }

        #expect(viewModel.stack == allScreens)

        // When
        viewModel.resetToRoot()

        // Then
        #expect(viewModel.stack == [.a])
    }

    // MARK: - Complex Navigation Tests

    @Test("Push → Pop → Push 시나리오")
    @MainActor
    func pushPopPushScenario() async throws {
        // Given
        let viewModel = NavigationStackViewModel()

        // When - Push B, C
        viewModel.updateCurrentScreen(.b)
        viewModel.updateCurrentScreen(.c)
        #expect(viewModel.stack == [.a, .b, .c])

        // When - Pop to A
        viewModel.updateCurrentScreen(.a)
        #expect(viewModel.stack == [.a])

        // When - Push D
        viewModel.updateCurrentScreen(.d)
        #expect(viewModel.stack == [.a, .d])
    }

    @Test("중간 화면으로 Pop 후 다른 경로 Push")
    @MainActor
    func popToMiddleThenPushDifferentPath() async throws {
        // Given
        let viewModel = NavigationStackViewModel()
        viewModel.updateCurrentScreen(.b)
        viewModel.updateCurrentScreen(.c)
        viewModel.updateCurrentScreen(.d)

        #expect(viewModel.stack == [.a, .b, .c, .d])

        // When - Pop to B
        viewModel.updateCurrentScreen(.b)
        #expect(viewModel.stack == [.a, .b])

        // When - Push E
        viewModel.updateCurrentScreen(.e)

        // Then
        #expect(viewModel.stack == [.a, .b, .e])
    }

    // MARK: - Edge Cases

    @Test("동일한 화면 연속 업데이트")
    @MainActor
    func updateSameScreenTwice() async throws {
        // Given
        let viewModel = NavigationStackViewModel()
        viewModel.updateCurrentScreen(.b)

        #expect(viewModel.stack == [.a, .b])

        // When - Screen B를 다시 업데이트
        viewModel.updateCurrentScreen(.b)

        // Then - 스택 변경 없음 (이미 마지막이므로)
        #expect(viewModel.stack == [.a, .b])
    }

    @Test("Root 화면 업데이트")
    @MainActor
    func updateToRootScreen() async throws {
        // Given
        let viewModel = NavigationStackViewModel()
        viewModel.updateCurrentScreen(.b)
        viewModel.updateCurrentScreen(.c)

        #expect(viewModel.stack == [.a, .b, .c])

        // When - Root(A)로 업데이트
        viewModel.updateCurrentScreen(.a)

        // Then - Root만 남음
        #expect(viewModel.stack == [.a])
    }

    @Test("빈 스택에서 화면 추가 (비정상적인 경우)")
    @MainActor
    func addScreenToEmptyStack() async throws {
        // Given
        let viewModel = NavigationStackViewModel()

        // When - B를 먼저 추가 (A를 건너뜀, 비정상)
        viewModel.updateCurrentScreen(.b)

        // Then - 스택에 B가 추가됨
        #expect(viewModel.stack == [.a, .b])
    }

    // MARK: - Publisher Tests

    @Test("스택 변경 시 Publisher 발행")
    @MainActor
    func stackPublisher() async throws {
        // Given
        let viewModel = NavigationStackViewModel()

        var receivedStacks: [[DemoStep.Screen]] = []
        let cancellable = viewModel.$stack
            .sink { stack in
                receivedStacks.append(stack)
            }

        // When
        viewModel.updateCurrentScreen(.b)
        viewModel.updateCurrentScreen(.c)

        // Wait for publisher
        await Test.wait(milliseconds: 100)

        // Then - 초기값 + 2번 업데이트
        #expect(receivedStacks.count >= 3)
        #expect(receivedStacks.last == [.a, .b, .c])

        cancellable.cancel()
    }

    // MARK: - Depth Calculation Tests

    @Test("다양한 깊이의 스택 상태 검증", arguments: [
        (screens: [DemoStep.Screen.a], expectedDepth: 0),
        (screens: [.a, .b], expectedDepth: 1),
        (screens: [.a, .b, .c], expectedDepth: 2),
        (screens: [.a, .b, .c, .d], expectedDepth: 3),
        (screens: [.a, .b, .c, .d, .e], expectedDepth: 4),
    ])
    @MainActor
    func stackDepth(screens: [DemoStep.Screen], expectedDepth: Int) async throws {
        // Given
        let viewModel = NavigationStackViewModel()

        // When
        for screen in screens.dropFirst() {
            viewModel.updateCurrentScreen(screen)
        }

        // Then
        #expect(viewModel.stack.count - 1 == expectedDepth)
        #expect(viewModel.stack == screens)
    }

    // MARK: - Singleton Tests

    @Test("Singleton 인스턴스 동일성 확인")
    @MainActor
    func singletonIdentity() async throws {
        // Given
        let instance1 = NavigationStackViewModel.shared
        let instance2 = NavigationStackViewModel.shared

        // Then
        #expect(instance1 === instance2)
    }
}
