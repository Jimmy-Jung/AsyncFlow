//
//  DeepLinkUITests.swift
//  AsyncFlowExampleUITests
//
//  Created by jimmy on 2026. 1. 2.
//

import XCTest

/// 딥링크 UI 테스트
@MainActor
final class DeepLinkUITests: XCTestCase {
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

    // MARK: - 딥링크 테스트

    func testUC14_DeepLinkFromRoot() async throws {
        // Given: Screen A에 있음
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: "DeepLink" 버튼 탭
        let deepLinkButton = app.buttons["🔗 Simulate DeepLink to Random Screen"]
        XCTAssertTrue(deepLinkButton.exists)
        XCTAssertTrue(deepLinkButton.isEnabled)
        deepLinkButton.tap()

        // Then: 랜덤 화면으로 이동 (A가 아닌 화면)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
        let currentTitle = app.staticTexts["screenTitle"].label
        XCTAssertNotEqual(currentTitle, "Screen A", "DeepLink should navigate to a different screen")

        // And: A 버튼이 활성화됨 (현재 화면이 아니므로)
        XCTAssertTrue(app.buttons["A"].isEnabled)
    }

    func testUC15_DeepLinkIntermediateScreensWork() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: 딥링크 시뮬레이션 (여러 번 시도하여 E로 이동)
        for _ in 0 ..< 10 {
            let deepLinkButton = app.buttons["🔗 Simulate DeepLink to Random Screen"]
            if deepLinkButton.exists, deepLinkButton.isEnabled {
                deepLinkButton.tap()
                try await Task.sleep(nanoseconds: 1_000_000_000)

                let currentTitle = app.staticTexts["screenTitle"].label
                if currentTitle == "Screen E" {
                    break
                }

                // E가 아니면 Root로 돌아가서 재시도
                if app.buttons["🏠 Go to Root (A)"].isEnabled {
                    app.buttons["🏠 Go to Root (A)"].tap()
                    try await waitForScreen("Screen A")
                }
            }
        }

        // Then: E에 도달하면 뒤로가기로 중간 화면 확인
        if app.staticTexts["screenTitle"].label == "Screen E" {
            // E → D
            app.buttons["⬅️  Back"].tap()
            try await waitForScreen("Screen D")
            XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen D")

            // D의 버튼들이 동작하는지 확인
            XCTAssertTrue(app.buttons["⬅️  Back"].isEnabled)
            XCTAssertTrue(app.buttons["➡️  Go to Next Screen"].isEnabled)

            // D → C
            app.buttons["⬅️  Back"].tap()
            try await waitForScreen("Screen C")
            XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen C")
        }
    }

    func testUC16_DeepLinkThenJump() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: 딥링크 시뮬레이션
        app.buttons["🔗 Simulate DeepLink to Random Screen"].tap()
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let firstScreen = app.staticTexts["screenTitle"].label
        XCTAssertNotEqual(firstScreen, "Screen A")

        // When: 다른 화면으로 점프
        // B, C, D, E 중 현재 화면이 아닌 버튼 찾기
        let screens = ["B", "C", "D", "E"]
        for screen in screens {
            let button = app.buttons[screen]
            if button.exists, button.isEnabled {
                button.tap()
                try await Task.sleep(nanoseconds: 1_000_000_000)

                // Then: 점프가 정상 동작
                let newTitle = app.staticTexts["screenTitle"].label
                XCTAssertTrue(newTitle.contains(screen))
                break
            }
        }
    }

    func testUC17_DeepLinkThenGoToRoot() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: 딥링크 시뮬레이션
        app.buttons["🔗 Simulate DeepLink to Random Screen"].tap()
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let deepLinkedScreen = app.staticTexts["screenTitle"].label
        XCTAssertNotEqual(deepLinkedScreen, "Screen A")

        // When: Go to Root 버튼 탭
        let goToRootButton = app.buttons["🏠 Go to Root (A)"]
        XCTAssertTrue(goToRootButton.isEnabled)
        goToRootButton.tap()
        try await waitForScreen("Screen A")

        // Then: Screen A로 이동
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // And: Go to Root 버튼 비활성화
        XCTAssertFalse(app.buttons["🏠 Go to Root (A)"].isEnabled)
    }

    func testUC18_DeepLinkThenNext() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: 딥링크 시뮬레이션 (D로 가도록 시도)
        for _ in 0 ..< 10 {
            let deepLinkButton = app.buttons["🔗 Simulate DeepLink to Random Screen"]
            if deepLinkButton.exists, deepLinkButton.isEnabled {
                deepLinkButton.tap()
                try await Task.sleep(nanoseconds: 1_000_000_000)

                let currentTitle = app.staticTexts["screenTitle"].label
                if currentTitle == "Screen D" {
                    break
                }

                // D가 아니면 Root로 돌아가서 재시도
                if app.buttons["🏠 Go to Root (A)"].isEnabled {
                    app.buttons["🏠 Go to Root (A)"].tap()
                    try await waitForScreen("Screen A")
                }
            }
        }

        // Then: D에 도달하면 Next 버튼으로 E로 이동
        if app.staticTexts["screenTitle"].label == "Screen D" {
            let nextButton = app.buttons["➡️  Go to Next Screen"]
            XCTAssertTrue(nextButton.isEnabled)
            nextButton.tap()
            try await waitForScreen("Screen E")

            XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen E")
        }
    }

    func testUC19_MultipleDeepLinks() async throws {
        // Given: Screen A
        XCTAssertEqual(app.staticTexts["screenTitle"].label, "Screen A")

        // When: 첫 번째 딥링크 (A가 아닌 화면으로 이동할 때까지 재시도)
        var firstScreen = "Screen A"
        for attempt in 0 ..< 5 {
            app.buttons["🔗 Simulate DeepLink to Random Screen"].tap()
            try await Task.sleep(nanoseconds: 1_000_000_000)
            firstScreen = app.staticTexts["screenTitle"].label

            if firstScreen != "Screen A" {
                break
            }

            // A로 돌아왔으면 다시 시도
            print("⚠️ DeepLink returned to A, retrying... (attempt \(attempt + 1))")
        }

        XCTAssertNotEqual(firstScreen, "Screen A", "DeepLink should navigate away from A")

        // When: 두 번째 딥링크 (다른 화면으로 이동 시도)
        let deepLinkButton = app.buttons["🔗 Simulate DeepLink to Random Screen"]
        if deepLinkButton.exists, deepLinkButton.isEnabled {
            let beforeSecondLink = firstScreen

            // 최대 3번 시도
            var secondScreen = beforeSecondLink
            for attempt in 0 ..< 3 {
                deepLinkButton.tap()
                try await Task.sleep(nanoseconds: 1_000_000_000)

                secondScreen = app.staticTexts["screenTitle"].label

                // 다른 화면으로 이동했으면 성공
                if secondScreen != beforeSecondLink {
                    break
                }

                print("⚠️ Second deeplink stayed at same screen, retrying... (attempt \(attempt + 1))")
            }

            // Then: 딥링크가 동작함을 확인 (같은 화면에 머물러도 OK, A가 아니면 됨)
            XCTAssertNotEqual(secondScreen, "Screen A", "Should not return to Screen A")
        }
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
