//
//  NavigationUITests.swift
//  AsyncFlowExampleUITests
//
//  Created by jimmy on 2026. 1. 2.
//

import XCTest

/// 선형 네비게이션 및 뒤로가기 UI 테스트
@MainActor
final class NavigationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // 완전히 새로운 앱 인스턴스
        app = XCUIApplication()

        // 앱 상태 초기화 (이전 실행 데이터 삭제)
        app.launchArguments = ["-UITestMode", "true"]
        app.launchEnvironment = ["RESET_STATE": "true"]

        app.launch()

        // 초기 화면이 로드될 때까지 대기
        let screenTitle = app.staticTexts["screenTitle"]
        _ = screenTitle.waitForExistence(timeout: 5.0)
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    // MARK: - 선형 네비게이션

    func testUC01_NavigationFromAToB() async throws {
        // Given: Screen A에 있음
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: "Go to Next Screen" 버튼 탭
        let nextButton = app.buttons["➡️  Go to Next Screen"]
        XCTAssertTrue(nextButton.exists)
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()

        // Then: Screen B로 이동
        try await waitForScreen("Screen B")
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen B")
        XCTAssertEqual(app.staticTexts["screenIcon"].label, "🟠")
    }

    func testUC02_NavigationFromAToC() async throws {
        // Given: Screen A에 있음
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: A에서 Next
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")

        // When: B에서 Next
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen C")

        // Then: Screen C로 이동
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen C")
        XCTAssertEqual(app.staticTexts["screenIcon"].label, "🟡")
    }

    func testUC03_FullLinearNavigation() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        let screens = ["Screen B", "Screen C", "Screen D", "Screen E"]
        let icons = ["🟠", "🟡", "🟢", "🔵"]

        // When: 모든 화면에서 순차적으로 Next 탭
        for (index, screen) in screens.enumerated() {
            app.buttons["➡️  Go to Next Screen"].tap()
            try await waitForScreen(screen)

            // Then: 각 화면 확인
            XCTAssertEqual(app.staticTexts["screenTitle"].label, screen)
            XCTAssertEqual(app.staticTexts["screenIcon"].label, icons[index])
        }

        // Then: 마지막 화면(E)에서 Next 버튼 비활성화
        let nextButton = app.buttons["➡️  Go to Next Screen"]
        XCTAssertFalse(nextButton.isEnabled)
    }

    // MARK: - 뒤로가기 네비게이션

    func testUC04_BackNavigation() async throws {
        // Given: A → B → C 상태
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen C")

        // When: C에서 "Back" 버튼 탭
        let backButton = app.buttons["⬅️  Back"]
        XCTAssertTrue(backButton.isEnabled)
        backButton.tap()
        try await waitForScreen("Screen B")

        // Then: Screen B로 이동
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen B")
    }

    func testUC05_BackTwoSteps() async throws {
        // Given: A → B → C 상태
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen B")
        app.buttons["➡️  Go to Next Screen"].tap()
        try await waitForScreen("Screen C")

        // When: C에서 "x2" 버튼 탭
        let back2Button = app.buttons["⬅️⬅️ x2"]
        XCTAssertTrue(back2Button.isEnabled)
        back2Button.tap()
        try await waitForScreen("Screen A")

        // Then: Screen A로 이동
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")
    }

    func testUC06_BackThreeSteps() async throws {
        // Given: A → B → C → D 상태
        for _ in 0 ..< 3 {
            app.buttons["➡️  Go to Next Screen"].tap()
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
        }
        try await waitForScreen("Screen D")

        // When: D에서 "x3" 버튼 탭
        let back3Button = app.buttons["⬅️⬅️⬅️ x3"]
        XCTAssertTrue(back3Button.isEnabled)
        back3Button.tap()
        try await waitForScreen("Screen A")

        // Then: Screen A로 이동
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")
    }

    func testUC07_GoToRoot() async throws {
        // Given: A → B → C → D 상태
        for _ in 0 ..< 3 {
            app.buttons["➡️  Go to Next Screen"].tap()
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        try await waitForScreen("Screen D")

        // When: D에서 "Go to Root (A)" 버튼 탭
        let goToRootButton = app.buttons["🏠 Go to Root (A)"]
        XCTAssertTrue(goToRootButton.isEnabled)
        goToRootButton.tap()
        try await waitForScreen("Screen A")

        // Then: Screen A로 이동
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // And: Go to Root 버튼 비활성화 (이미 Root에 있으므로)
        XCTAssertFalse(app.buttons["🏠 Go to Root (A)"].isEnabled)
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
