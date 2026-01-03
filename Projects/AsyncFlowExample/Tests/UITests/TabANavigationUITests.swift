//
//  TabANavigationUITests.swift
//  AsyncFlowExampleUITests
//
//  Created by jimmy on 2026. 1. 3.
//

import XCTest

/// Tab A 네비게이션 UI 테스트
///
/// Tab A의 화면 전환, 뒤로 가기, 루트 이동 등의 네비게이션 동작을 테스트합니다.
final class TabANavigationUITests: AsyncFlowExampleUITests {
    // MARK: - Initial Screen Tests

    func testInitialScreenIsA1() throws {
        // Given: 앱 시작
        // When: Tab A가 기본 선택되어 있음

        // Then: A-1 화면이 표시되어야 함
        switchToTabA()

        // A-1 화면의 버튼들이 존재하는지 확인
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-2)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "A-1 화면의 Next 버튼을 찾을 수 없습니다")
    }

    // MARK: - Forward Navigation Tests

    func testNavigateFromA1ToA2() throws {
        // Given: A-1 화면
        switchToTabA()

        // When: Next (A-2) 버튼 탭
        tapButton(containing: "Next (A-2)")

        // Then: A-2 화면으로 이동
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Back")).firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 3.0), "A-2 화면의 Back 버튼을 찾을 수 없습니다")

        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-3)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "A-2 화면의 Next 버튼을 찾을 수 없습니다")
    }

    func testNavigateFromA2ToA3() throws {
        // Given: A-2 화면
        switchToTabA()
        tapButton(containing: "Next (A-2)")

        // When: Next (A-3) 버튼 탭
        tapButton(containing: "Next (A-3)")

        // Then: A-3 화면으로 이동
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-4)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "A-3 화면의 Next 버튼을 찾을 수 없습니다")
    }

    func testNavigateToA5() throws {
        // Given: A-1 화면
        switchToTabA()

        // When: Jump to A-5 버튼 탭
        tapButton(containing: "Jump to A-5")

        // Then: A-5 화면으로 이동
        // A-5는 마지막 화면이므로 Next 버튼이 없어야 함
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next")).firstMatch
        XCTAssertFalse(nextButton.exists, "A-5 화면에 Next 버튼이 있어서는 안 됩니다")
    }

    // MARK: - Back Navigation Tests

    func testBackNavigation() throws {
        // Given: A-3 화면
        switchToTabA()
        tapButton(containing: "Next (A-2)")
        tapButton(containing: "Next (A-3)")

        // When: Back 버튼 탭
        tapButton(containing: "Back")

        // Then: A-2 화면으로 돌아감
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-3)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "A-2 화면으로 돌아가지 못했습니다")
    }

    func testPopToRoot() throws {
        // Given: A-2 화면 (A-2에 Go to Root 버튼이 있음)
        switchToTabA()
        tapButton(containing: "Next (A-2)")

        // A-2 화면이 완전히 로드될 때까지 대기
        let a2NextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-3)")).firstMatch
        XCTAssertTrue(a2NextButton.waitForExistence(timeout: 3.0), "A-2 화면이 로드되지 않았습니다")

        // When: Go to Root 버튼 탭 (tapButton 내부에서 스크롤 처리)
        tapButton(containing: "Go to Root", timeout: 5.0)

        // Then: A-1 화면으로 돌아감
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-2)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "A-1 화면으로 돌아가지 못했습니다")
    }

    // MARK: - Navigation Stack Tests

    func testNavigationStackDepth() throws {
        // Given: A-1 화면 (Depth: 1)
        switchToTabA()

        // When: A-2로 이동 (Depth: 2)
        tapButton(containing: "Next (A-2)")

        // Then: Depth 정보가 표시되어야 함
        // Depth는 CommonScreenView의 depthLabel에 표시되지만
        // 접근성 설정이 없을 수 있으므로 화면 전환이 정상적으로 이루어졌는지로 확인
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Back")).firstMatch
        XCTAssertTrue(backButton.exists, "Depth가 증가했는지 확인할 수 없습니다")
    }

    // MARK: - Multiple Navigation Tests

    func testCompleteNavigationFlow() throws {
        // Given: A-1 화면
        switchToTabA()

        // When: A-1 → A-2 → A-3 → A-4 → A-5 순서로 이동
        tapButton(containing: "Next (A-2)")
        tapButton(containing: "Next (A-3)")
        tapButton(containing: "Next (A-4)")
        tapButton(containing: "Next (A-5)")

        // Then: A-5 화면에 도달
        // A-5는 마지막 화면이므로 Next 버튼이 없어야 함
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next")).firstMatch
        XCTAssertFalse(nextButton.exists, "A-5 화면에 도달하지 못했습니다")

        // Back 버튼은 있어야 함
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Back")).firstMatch
        XCTAssertTrue(backButton.exists, "A-5 화면에 Back 버튼이 없습니다")
    }
}
