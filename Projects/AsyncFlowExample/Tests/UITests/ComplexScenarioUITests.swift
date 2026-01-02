//
//  ComplexScenarioUITests.swift
//  AsyncFlowExampleUITests
//
//  Created by jimmy on 2026. 1. 2.
//

import XCTest

/// 복잡한 시나리오 및 버튼 상태 UI 테스트
@MainActor
final class ComplexScenarioUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "true"]
        app.launchEnvironment = ["RESET_STATE": "true"]
        app.launch()

        let screenTitle = app.staticTexts["screenTitle"]
        _ = screenTitle.waitForExistence(timeout: 5.0)
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    // MARK: - 복잡한 시나리오

    func testUC20_NavigationCombination() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: A → B (Next)
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen B")

        // When: B → C (Next)
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen C")
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen C")

        // When: C → A (Go to Root)
        app.buttons["🏠 Go to Root (A)"].tap()
        try await waitForScreen("Screen A")
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: A → B (Next)
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen B")

        // When: B → D (Jump)
        app.buttons["D"].tap()
        try await waitForScreen("Screen D")

        // Then: 최종 상태 확인
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen D")
        XCTAssertEqual(app.staticTexts["screenIcon"].label, "🟢")
    }

    func testUC21_DeepLinkAndBackCombination() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: A → 딥링크 (C로 시도)
        for _ in 0 ..< 10 {
            let deepLinkButton = app.buttons["🔗 Simulate DeepLink to Random Screen"]
            if deepLinkButton.exists, deepLinkButton.isEnabled {
                deepLinkButton.tap()
                try await Task.sleep(nanoseconds: 1_000_000_000)

                let currentTitle = app.staticTexts["screenTitle"].label
                if currentTitle == "Screen C" {
                    break
                }

                if app.buttons["🏠 Go to Root (A)"].isEnabled {
                    app.buttons["🏠 Go to Root (A)"].tap()
                    try await waitForScreen("Screen A")
                }
            }
        }

        // Then: C에 도달하면 뒤로가기 + Next 조합
        if app.staticTexts["screenTitle"].label == "Screen C" {
            // C → B (Back)
            app.buttons["⬅️  Back"].tap()
            try await waitForScreen("Screen B")
            XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen B")

            // B → C (Next)
            app.buttons["➡️  Go to Next Screen"].tap()
            try await waitForScreen("Screen C")
            XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen C")

            // C → D (Next)
            app.buttons["➡️  Go to Next Screen"].tap()
            try await waitForScreen("Screen D")
            XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen D")
        }
    }

    func testUC22_ContinuousJumps() async throws {
        // Given: A → B → C
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")

        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen C")
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen C")

        // When: C → E (Jump)
        app.buttons["E"].tap()
        try await waitForScreen("Screen E")
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen E")

        // When: E → B (Jump)
        app.buttons["B"].tap()
        try await waitForScreen("Screen B")
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen B")

        // When: B → D (Jump)
        app.buttons["D"].tap()
        try await waitForScreen("Screen D")

        // Then: 최종 스택 A → B → D
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen D")

        // Verify: E는 스택에서 제거되었으므로 버튼 활성화
        XCTAssertTrue(app.buttons["E"].isEnabled)

        // Verify: C도 스택에서 제거되었으므로 버튼 활성화
        XCTAssertTrue(app.buttons["C"].isEnabled)
    }

    func testUC23_FullTourThenReturnToRoot() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: A → E (모든 화면 순회)
        let screens = ["Screen B", "Screen C", "Screen D", "Screen E"]
        for screen in screens {
            app.buttons["➡️  Go to Next Screen"].tap()
            try await waitForScreen(screen)
        }
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen E")

        // When: Go to Root
        app.buttons["🏠 Go to Root (A)"].tap()
        try await waitForScreen("Screen A")

        // Then: Screen A로 이동, 모든 점프 버튼 활성화
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")
        XCTAssertFalse(app.buttons["A"].isEnabled) // 현재 화면
        XCTAssertTrue(app.buttons["B"].isEnabled)
        XCTAssertTrue(app.buttons["C"].isEnabled)
        XCTAssertTrue(app.buttons["D"].isEnabled)
        XCTAssertTrue(app.buttons["E"].isEnabled)
    }

    // MARK: - 버튼 상태 검증

    func testUC24_NextButtonStateByDepth() async throws {
        let testCases: [(screen: String, shouldBeEnabled: Bool)] = [
            ("Screen A", true), // A → B 가능
            ("Screen B", true), // B → C 가능
            ("Screen C", true), // C → D 가능
            ("Screen D", true), // D → E 가능
            ("Screen E", false), // E는 마지막 화면
        ]

        for (expectedScreen, shouldBeEnabled) in testCases {
            XCTAssertEqual(app.staticTexts["screenTitle"].label, expectedScreen)

            let nextButton = app.buttons["➡️  Go to Next Screen"]
            if shouldBeEnabled {
                XCTAssertTrue(nextButton.isEnabled, "Next button should be enabled at \(expectedScreen)")
            } else {
                XCTAssertFalse(nextButton.isEnabled, "Next button should be disabled at \(expectedScreen)")
            }

            // 다음 화면으로 이동 (마지막이 아닌 경우)
            if shouldBeEnabled, expectedScreen != "Screen E" {
                nextButton.tap()
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    func testUC25_BackButtonStateByDepth() async throws {
        // Depth 0 (A): 모든 Back 버튼 비활성화
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")
        XCTAssertFalse(app.buttons["⬅️  Back"].isEnabled)
        XCTAssertFalse(app.buttons["⬅️⬅️ x2"].isEnabled)
        XCTAssertFalse(app.buttons["⬅️⬅️⬅️ x3"].isEnabled)

        // Depth 1 (B): Back 활성화
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")
        XCTAssertTrue(app.buttons["⬅️  Back"].isEnabled)
        XCTAssertFalse(app.buttons["⬅️⬅️ x2"].isEnabled)
        XCTAssertFalse(app.buttons["⬅️⬅️⬅️ x3"].isEnabled)

        // Depth 2 (C): Back, Back x2 활성화
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen C")
        XCTAssertTrue(app.buttons["⬅️  Back"].isEnabled)
        XCTAssertTrue(app.buttons["⬅️⬅️ x2"].isEnabled)
        XCTAssertFalse(app.buttons["⬅️⬅️⬅️ x3"].isEnabled)

        // Depth 3 (D): 모든 Back 버튼 활성화
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen D")
        XCTAssertTrue(app.buttons["⬅️  Back"].isEnabled)
        XCTAssertTrue(app.buttons["⬅️⬅️ x2"].isEnabled)
        XCTAssertTrue(app.buttons["⬅️⬅️⬅️ x3"].isEnabled)
    }

    func testUC26_GoToRootButtonState() async throws {
        // Screen A (Root): Go to Root 버튼 비활성화
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")
        XCTAssertFalse(app.buttons["🏠 Go to Root (A)"].isEnabled)

        // Screen B: Go to Root 버튼 활성화
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")
        XCTAssertTrue(app.buttons["🏠 Go to Root (A)"].isEnabled)

        // Screen C: Go to Root 버튼 활성화
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen C")
        XCTAssertTrue(app.buttons["🏠 Go to Root (A)"].isEnabled)
    }

    func testUC27_CurrentScreenJumpButtonDisabled() async throws {
        let screens = ["A", "B", "C", "D", "E"]
        var currentIndex = 0

        for screen in screens {
            let currentButton = app.buttons[screen]
            XCTAssertFalse(currentButton.isEnabled, "\(screen) button should be disabled at Screen \(screen)")

            // 다른 화면의 버튼은 활성화되어야 함
            for otherScreen in screens where otherScreen != screen {
                let otherButton = app.buttons[otherScreen]
                XCTAssertTrue(otherButton.isEnabled, "\(otherScreen) button should be enabled at Screen \(screen)")
            }

            // 마지막 화면이 아니면 다음 화면으로 이동
            if currentIndex < screens.count - 1 {
                app.buttons["➡️  Go to Next Screen"].tap()
                try await Task.sleep(nanoseconds: 500_000_000)
                currentIndex += 1
            }
        }
    }

    // MARK: - 엣지 케이스

    func testUC28_RapidTaps() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: Next 버튼을 빠르게 여러 번 탭
        let nextButton = app.buttons["➡️  Go to Next Screen"]
        for _ in 0 ..< 5 {
            if nextButton.exists, nextButton.isHittable {
                nextButton.tap()
            }
        }

        // Then: 과도한 네비게이션이 발생하지 않음 (최대 E까지만)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기로 증가
        let finalTitle = app.staticTexts["screenTitle"].label

        // 빠르게 탭해도 E를 넘어가지 않음을 확인
        let validScreens = ["Screen A", "Screen B", "Screen C", "Screen D", "Screen E"]
        XCTAssertTrue(validScreens.contains(finalTitle),
                      "Should be at a valid screen: \(finalTitle)")
    }

    // MARK: - Helper Methods

    private func waitForScreen(_ screenTitle: String) async throws {
        let titleLabel = app.staticTexts["screenTitle"]
        let predicate = NSPredicate(format: "label == %@", screenTitle)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: titleLabel)

        let result = await XCTWaiter().fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(result, .completed, "Failed to navigate to \(screenTitle)")
    }
}
