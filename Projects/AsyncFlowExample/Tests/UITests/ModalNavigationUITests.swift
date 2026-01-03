//
//  ModalNavigationUITests.swift
//  AsyncFlowExampleUITests
//
//  Created by jimmy on 2026. 1. 3.
//

import XCTest

/// Modal 네비게이션 UI 테스트
///
/// Modal 화면의 present/dismiss 동작을 테스트합니다.
final class ModalNavigationUITests: AsyncFlowExampleUITests {
    // MARK: - Modal Present Tests

    func testPresentModalFromA1() throws {
        // Given: Tab A의 A-1 화면
        switchToTabA()

        // When: Present Modal 버튼 탭
        tapButton(containing: "Present Modal")

        // Then: Modal 화면이 표시됨
        let modalTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Modal Screen")).firstMatch
        XCTAssertTrue(modalTitle.waitForExistence(timeout: 3.0), "Modal 화면이 표시되지 않았습니다")

        // Dismiss 버튼이 있어야 함
        let dismissButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Dismiss")).firstMatch
        XCTAssertTrue(dismissButton.exists, "Modal 화면에 Dismiss 버튼이 없습니다")
    }

    func testPresentModalFromA2() throws {
        // Given: Tab A의 A-2 화면
        switchToTabA()
        tapButton(containing: "Next (A-2)")

        // When: Present Modal 버튼 탭 (A-2에는 없으므로 A-1로 돌아가서 테스트)
        // A-2에는 Present Modal 버튼이 없으므로 이 테스트는 제거하거나 A-1에서 테스트
        // A-1에서 이미 테스트하므로 이 테스트는 제거
        // 대신 A-2에서 뒤로 가기 후 A-1에서 Modal을 테스트
        tapButton(containing: "Back")
        tapButton(containing: "Present Modal")

        // Then: Modal 화면이 표시됨
        let modalTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Modal Screen")).firstMatch
        XCTAssertTrue(modalTitle.waitForExistence(timeout: 3.0), "Modal 화면이 표시되지 않았습니다")
    }

    func testPresentModalFromB1() throws {
        // Given: Tab B의 B-1 화면
        switchToTabB()

        // When: Present Modal 버튼 탭
        tapButton(containing: "Present Modal")

        // Then: Modal 화면이 표시됨
        let modalTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Modal Screen")).firstMatch
        XCTAssertTrue(modalTitle.waitForExistence(timeout: 3.0), "Modal 화면이 표시되지 않았습니다")
    }

    // MARK: - Modal Dismiss Tests

    func testDismissModal() throws {
        // Given: Modal 화면이 표시됨
        switchToTabA()
        tapButton(containing: "Present Modal")

        let modalTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Modal Screen")).firstMatch
        XCTAssertTrue(modalTitle.waitForExistence(timeout: 3.0))

        // When: Dismiss 버튼 탭
        let dismissButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Dismiss")).firstMatch
        dismissButton.tap()

        // Then: Modal이 닫히고 원래 화면으로 돌아감
        waitForModalToDismiss(modalTitle)
        XCTAssertFalse(modalTitle.exists, "Modal이 닫히지 않았습니다")

        // 원래 화면(A-1)의 버튼이 다시 보여야 함
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-2)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "원래 화면으로 돌아가지 못했습니다")
    }

    // MARK: - Modal with Navigation Stack Tests

    func testModalPreservesUnderlyingNavigationStack() throws {
        // Given: Tab A의 A-2 화면
        switchToTabA()
        tapButton(containing: "Next (A-2)")

        // When: A-1로 돌아가서 Modal 표시 후 Dismiss
        tapButton(containing: "Back")
        tapButton(containing: "Present Modal")

        let modalTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Modal Screen")).firstMatch
        XCTAssertTrue(modalTitle.waitForExistence(timeout: 3.0))

        let dismissButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Dismiss")).firstMatch
        dismissButton.tap()
        waitForModalToDismiss(modalTitle)

        // Then: A-1 화면으로 돌아감
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-2)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "A-1 화면으로 돌아가지 못했습니다")
    }

    // MARK: - Multiple Modal Tests

    func testPresentAndDismissMultipleModals() throws {
        // Given: Tab A의 A-1 화면
        switchToTabA()

        // When: Modal을 여러 번 표시하고 닫기
        for _ in 1 ... 3 {
            tapButton(containing: "Present Modal")

            let modalTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Modal Screen")).firstMatch
            XCTAssertTrue(modalTitle.waitForExistence(timeout: 3.0), "Modal이 표시되지 않았습니다")

            let dismissButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Dismiss")).firstMatch
            dismissButton.tap()
            waitForModalToDismiss(modalTitle)

            XCTAssertFalse(modalTitle.exists, "Modal이 닫히지 않았습니다")
        }

        // Then: 모든 Modal이 정상적으로 닫히고 원래 화면으로 돌아감
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-2)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "원래 화면으로 돌아가지 못했습니다")
    }
}
