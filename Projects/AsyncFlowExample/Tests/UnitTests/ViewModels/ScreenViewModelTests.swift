//
//  ScreenViewModelTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 2.
//

@testable import AsyncFlow
@testable import AsyncFlowExample
import AsyncViewModel
import Foundation
import Testing

// MARK: - ScreenViewModel Unit Tests

@Suite("ScreenViewModel 단위 테스트", .tags(.viewModel, .unit, .asyncViewModel))
struct ScreenViewModelTests {
    // MARK: - Initial State Tests

    @Test("Screen A 초기 상태 검증")
    @MainActor
    func screenAInitialState() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .a, depth: 0)
        let store = AsyncTestStore(viewModel: viewModel)

        // Then
        #expect(store.state.config.screen == .a)
        #expect(store.state.config.title == "Screen A")
        #expect(store.state.canGoBack == false)
        #expect(store.state.canGoBack2 == false)
        #expect(store.state.canGoBack3 == false)
        #expect(store.state.canGoToRoot == false)
        #expect(store.state.nextScreen == .b)

        store.cleanup()
    }

    @Test("Screen B 초기 상태 검증")
    @MainActor
    func screenBInitialState() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .b, depth: 1)
        let store = AsyncTestStore(viewModel: viewModel)

        // Then
        #expect(store.state.config.screen == .b)
        #expect(store.state.canGoBack == true)
        #expect(store.state.canGoBack2 == false)
        #expect(store.state.canGoToRoot == true)
        #expect(store.state.nextScreen == .c)

        store.cleanup()
    }

    @Test("Screen E 초기 상태 검증 (마지막 화면)")
    @MainActor
    func screenEInitialState() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .e, depth: 4)
        let store = AsyncTestStore(viewModel: viewModel)

        // Then
        #expect(store.state.config.screen == .e)
        #expect(store.state.canGoBack == true)
        #expect(store.state.canGoBack2 == true)
        #expect(store.state.canGoBack3 == true)
        #expect(store.state.canGoToRoot == true)
        #expect(store.state.nextScreen == nil) // 마지막 화면이므로 nil

        store.cleanup()
    }

    @Test("다양한 depth에서 버튼 활성화 상태", arguments: [
        (depth: 0, canGoBack: false, canGoBack2: false, canGoBack3: false),
        (depth: 1, canGoBack: true, canGoBack2: false, canGoBack3: false),
        (depth: 2, canGoBack: true, canGoBack2: true, canGoBack3: false),
        (depth: 3, canGoBack: true, canGoBack2: true, canGoBack3: true),
    ])
    @MainActor
    func buttonStatesAtDepth(
        depth: Int,
        canGoBack: Bool,
        canGoBack2: Bool,
        canGoBack3: Bool
    ) async throws {
        // Given
        let screen: DemoStep.Screen = .a
        let viewModel = ScreenViewModel(screen: screen, depth: depth)
        let store = AsyncTestStore(viewModel: viewModel)

        // Then
        #expect(store.state.canGoBack == canGoBack)
        #expect(store.state.canGoBack2 == canGoBack2)
        #expect(store.state.canGoBack3 == canGoBack3)
        #expect(store.state.canGoToRoot == (depth >= 1))

        store.cleanup()
    }

    // MARK: - Transform Tests

    @Test("nextButtonTapped → navigateToNext Action 변환")
    @MainActor
    func nextButtonTransform() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .a, depth: 0)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        let actions = viewModel.transform(.nextButtonTapped)

        // Then
        #expect(actions == [.navigateToNext])

        store.cleanup()
    }

    @Test("backButtonTapped → navigateBack Action 변환", arguments: [1, 2, 3])
    @MainActor
    func backButtonTransform(count: Int) async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .c, depth: 2)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        let actions = viewModel.transform(.backButtonTapped(count))

        // Then
        #expect(actions == [.navigateBack(count)])

        store.cleanup()
    }

    @Test("goToRootButtonTapped → navigateToRoot Action 변환")
    @MainActor
    func goToRootTransform() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .c, depth: 2)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        let actions = viewModel.transform(.goToRootButtonTapped)

        // Then
        #expect(actions == [.navigateToRoot])

        store.cleanup()
    }

    @Test("jumpToScreenButtonTapped → navigateToScreen Action 변환")
    @MainActor
    func jumpToScreenTransform() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .a, depth: 0)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        let actions = viewModel.transform(.jumpToScreenButtonTapped(.d))

        // Then
        #expect(actions == [.navigateToScreen(.d)])

        store.cleanup()
    }

    @Test("deepLinkButtonTapped → navigateDeepLink Action 변환")
    @MainActor
    func deepLinkTransform() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .a, depth: 0)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        let actions = viewModel.transform(.deepLinkButtonTapped(.c))

        // Then
        #expect(actions == [.navigateDeepLink(.c)])

        store.cleanup()
    }

    @Test("viewDidAppear → 빈 Action 배열")
    @MainActor
    func viewLifecycleTransform() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .a, depth: 0)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        let appearActions = viewModel.transform(.viewDidAppear)
        let disappearActions = viewModel.transform(.viewDidDisappear)

        // Then
        #expect(appearActions.isEmpty)
        #expect(disappearActions.isEmpty)

        store.cleanup()
    }

    // MARK: - Navigation Action Tests

    @Test("다음 화면 이동 시 Step 발행")
    @MainActor
    func nextButtonEmitsStep() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .a, depth: 0)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.nextButtonTapped)

        // Then
        try await store.waitForEffects()
        #expect(store.actions.contains(.navigateToNext))

        store.cleanup()
    }

    @Test("1단계 뒤로 가기 Step 발행")
    @MainActor
    func goBackEmitsStep() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .c, depth: 2)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.backButtonTapped(1))

        // Then
        try await store.waitForEffects()
        #expect(store.actions.contains(.navigateBack(1)))

        store.cleanup()
    }

    @Test("2단계 뒤로 가기 Step 발행")
    @MainActor
    func goBack2EmitsStep() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .c, depth: 2)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.backButtonTapped(2))

        // Then
        try await store.waitForEffects()
        #expect(store.actions.contains(.navigateBack(2)))

        store.cleanup()
    }

    @Test("루트로 이동 Step 발행")
    @MainActor
    func goToRootEmitsStep() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .d, depth: 3)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.goToRootButtonTapped)

        // Then
        try await store.waitForEffects()
        #expect(store.actions.contains(.navigateToRoot))

        store.cleanup()
    }

    @Test("특정 화면으로 점프 Step 발행")
    @MainActor
    func jumpToScreenEmitsStep() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .a, depth: 0)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.jumpToScreenButtonTapped(.d))

        // Then
        try await store.waitForEffects()
        #expect(store.actions.contains(.navigateToScreen(.d)))

        store.cleanup()
    }

    @Test("DeepLink Step 발행")
    @MainActor
    func deepLinkEmitsStep() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .d, depth: 3)
        let store = AsyncTestStore(viewModel: viewModel)

        // When
        store.send(.deepLinkButtonTapped(.b))

        // Then
        try await store.waitForEffects()
        #expect(store.actions.contains(.navigateDeepLink(.b)))

        store.cleanup()
    }

    // MARK: - Edge Cases

    @Test("마지막 화면에서 Next 버튼 동작")
    @MainActor
    func nextFromLastScreen() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .e, depth: 4)
        let store = AsyncTestStore(viewModel: viewModel)

        #expect(store.state.nextScreen == nil)

        // When - Next 버튼이 비활성화되어야 하므로 아무 일도 발생하지 않음
        store.send(.nextButtonTapped)

        // Then
        try await store.waitForEffects()
        // State 변경 없음
        #expect(store.state.nextScreen == nil)

        store.cleanup()
    }

    @Test("Depth 0에서 뒤로 가기 시도")
    @MainActor
    func backFromRoot() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .a, depth: 0)
        let store = AsyncTestStore(viewModel: viewModel)

        #expect(store.state.canGoBack == false)

        // When - Back 버튼이 비활성화되어야 함
        store.send(.backButtonTapped(1))

        // Then
        try await store.waitForEffects()
        // Step은 발행되지만 Flow에서 처리되지 않음
        #expect(store.actions.contains(.navigateBack(1)))

        store.cleanup()
    }

    // MARK: - FlowStepper Protocol Tests

    @Test("readyToEmitSteps 호출 검증")
    @MainActor
    func testReadyToEmitSteps() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .a, depth: 0)

        // When - 이 메서드는 FlowCoordinator가 Stepper를 구독할 때 호출됨
        viewModel.readyToEmitSteps()

        // Then - 에러가 발생하지 않으면 성공
        #expect(Bool(true))
    }

    @Test("initialStep이 NoneStep인지 확인")
    @MainActor
    func testInitialStep() async throws {
        // Given
        let viewModel = ScreenViewModel(screen: .a, depth: 0)

        // When
        let initialStep = viewModel.initialStep

        // Then
        #expect(initialStep is NoneStep)
    }
}
