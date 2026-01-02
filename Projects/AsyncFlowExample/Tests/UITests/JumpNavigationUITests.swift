//
//  JumpNavigationUITests.swift
//  AsyncFlowExampleUITests
//
//  Created by jimmy on 2026. 1. 2.
//

import XCTest

/// 특정 화면 점프 네비게이션 UI 테스트
@MainActor
final class JumpNavigationUITests: XCTestCase {
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

    // MARK: - 특정 화면 점프

    func testUC08_JumpToNewScreen() async throws {
        // Given: A → B 상태
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")

        // When: B에서 "D" 버튼 탭
        let buttonD = app.buttons["D"]
        XCTAssertTrue(buttonD.exists)
        XCTAssertTrue(buttonD.isEnabled)
        buttonD.tap()
        try await waitForScreen("Screen D")

        // Then: Screen D로 이동
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen D")
        XCTAssertEqual(app.staticTexts["screenIcon"].label, "🟢")
    }

    func testUC09_JumpToExistingScreen() async throws {
        // Given: A → B → C 상태
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen C")

        // When: C에서 "B" 버튼 탭
        let buttonB = app.buttons["B"]
        XCTAssertTrue(buttonB.exists)
        XCTAssertTrue(buttonB.isEnabled)
        buttonB.tap()
        try await waitForScreen("Screen B")

        // Then: Screen B로 이동 (C가 스택에서 제거됨)
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen B")

        // And: C 버튼이 활성화됨 (스택에서 제거되었으므로)
        let buttonC = app.buttons["C"]
        XCTAssertTrue(buttonC.isEnabled)
    }

    func testUC10_CurrentScreenButtonDisabled() async throws {
        // Given: A → B 상태
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")

        // When: UI 확인
        let buttonB = app.buttons["B"]

        // Then: "B" 버튼이 비활성화 상태
        XCTAssertTrue(buttonB.exists)
        XCTAssertFalse(buttonB.isEnabled)
    }

    func testUC11_MultipleJumps() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: A → C (점프)
        app.buttons["C"].tap()
        try await waitForScreen("Screen C")
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen C")

        // When: C → E (점프)
        app.buttons["E"].tap()
        try await waitForScreen("Screen E")
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen E")

        // When: E → B (점프, Pop)
        app.buttons["B"].tap()
        try await waitForScreen("Screen B")

        // Then: Screen B로 이동
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen B")

        // And: E 버튼이 활성화됨 (스택에서 제거되었으므로)
        XCTAssertTrue(app.buttons["E"].isEnabled)
    }

    func testUC12_JumpToRoot() async throws {
        // Given: A → B → C → D 상태
        for _ in 0 ..< 3 {
            app.buttons["➡️  Go to Next Screen"].tap()
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        try await waitForScreen("Screen D")

        // When: D에서 "A" 버튼 탭
        let buttonA = app.buttons["A"]
        XCTAssertTrue(buttonA.exists)
        XCTAssertTrue(buttonA.isEnabled)
        buttonA.tap()
        try await waitForScreen("Screen A")

        // Then: Screen A로 이동
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // And: A 버튼 비활성화, 모든 다른 버튼 활성화
        XCTAssertFalse(app.buttons["A"].isEnabled)
        XCTAssertTrue(app.buttons["B"].isEnabled)
        XCTAssertTrue(app.buttons["C"].isEnabled)
        XCTAssertTrue(app.buttons["D"].isEnabled)
        XCTAssertTrue(app.buttons["E"].isEnabled)
    }

    func testUC13_JumpThenContinue() async throws {
        // Given: A → C (점프)
        app.buttons["C"].tap()
        try await waitForScreen("Screen C")

        // When: C에서 Next 버튼 탭
        let nextButton = app.buttons["➡️  Go to Next Screen"]
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()
        try await waitForScreen("Screen D")

        // Then: Screen D로 이동
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen D")
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
