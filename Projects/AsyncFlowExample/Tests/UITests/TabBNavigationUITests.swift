//
//  TabBNavigationUITests.swift
//  AsyncFlowExampleUITests
//
//  Created by jimmy on 2026. 1. 3.
//

import XCTest

/// Tab B 네비게이션 UI 테스트
///
/// Tab B의 화면 전환, 뒤로 가기, 루트 이동 등의 네비게이션 동작을 테스트합니다.
final class TabBNavigationUITests: AsyncFlowExampleUITests {
    // MARK: - Initial Screen Tests

    func testInitialScreenIsB1() throws {
        // Given: 앱 시작
        // When: Tab B로 전환

        // Then: B-1 화면이 표시되어야 함
        switchToTabB()

        // B-1 화면의 버튼들이 존재하는지 확인
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-2)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "B-1 화면의 Next 버튼을 찾을 수 없습니다")
    }

    // MARK: - Forward Navigation Tests

    func testNavigateFromB1ToB2() throws {
        // Given: B-1 화면
        switchToTabB()

        // When: Next (B-2) 버튼 탭
        tapButton(containing: "Next (B-2)")

        // Then: B-2 화면으로 이동
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Back")).firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 3.0), "B-2 화면의 Back 버튼을 찾을 수 없습니다")

        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-3)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "B-2 화면의 Next 버튼을 찾을 수 없습니다")
    }

    func testNavigateFromB2ToB3() throws {
        // Given: B-2 화면
        switchToTabB()
        tapButton(containing: "Next (B-2)")

        // When: Next (B-3) 버튼 탭
        tapButton(containing: "Next (B-3)")

        // Then: B-3 화면으로 이동
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-4)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "B-3 화면의 Next 버튼을 찾을 수 없습니다")
    }

    func testNavigateToB4() throws {
        // Given: B-1 화면
        switchToTabB()

        // When: Jump to B-4 버튼 탭
        tapButton(containing: "Jump to B-4")

        // Then: B-4 화면으로 이동
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-5)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "B-4 화면으로 이동하지 못했습니다")
    }

    // MARK: - Back Navigation Tests

    func testBackNavigation() throws {
        // Given: B-3 화면
        switchToTabB()
        tapButton(containing: "Next (B-2)")
        tapButton(containing: "Next (B-3)")

        // When: Back 버튼 탭
        tapButton(containing: "Back")

        // Then: B-2 화면으로 돌아감
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-3)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "B-2 화면으로 돌아가지 못했습니다")
    }

    func testPopToRoot() throws {
        // Given: B-2 화면 (B-2에 Go to Root 버튼이 있음)
        switchToTabB()
        tapButton(containing: "Next (B-2)")

        // B-2 화면이 완전히 로드될 때까지 대기
        let b2NextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-3)")).firstMatch
        XCTAssertTrue(b2NextButton.waitForExistence(timeout: 3.0), "B-2 화면이 로드되지 않았습니다")

        // When: Go to Root 버튼 탭 (tapButton 내부에서 스크롤 처리)
        tapButton(containing: "Go to Root", timeout: 5.0)

        // Then: B-1 화면으로 돌아감
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-2)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "B-1 화면으로 돌아가지 못했습니다")
    }

    // MARK: - Complete Navigation Flow

    func testCompleteNavigationFlow() throws {
        // Given: B-1 화면
        switchToTabB()

        // When: B-1 → B-2 → B-3 → B-4 → B-5 순서로 이동
        tapButton(containing: "Next (B-2)")
        tapButton(containing: "Next (B-3)")
        tapButton(containing: "Next (B-4)")
        tapButton(containing: "Next (B-5)")

        // Then: B-5 화면에 도달
        // B-5는 마지막 화면이므로 Next 버튼이 없어야 함
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next")).firstMatch
        XCTAssertFalse(nextButton.exists, "B-5 화면에 도달하지 못했습니다")

        // Back 버튼은 있어야 함
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Back")).firstMatch
        XCTAssertTrue(backButton.exists, "B-5 화면에 Back 버튼이 없습니다")
    }
}
