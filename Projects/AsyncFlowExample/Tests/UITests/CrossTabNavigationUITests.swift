//
//  CrossTabNavigationUITests.swift
//  AsyncFlowExampleUITests
//
//  Created by jimmy on 2026. 1. 3.
//

import XCTest

/// 크로스 탭 네비게이션 UI 테스트
///
/// 한 탭에서 다른 탭의 특정 화면으로 직접 이동하는 기능을 테스트합니다.
final class CrossTabNavigationUITests: AsyncFlowExampleUITests {
    // MARK: - Tab A to Tab B Tests

    func testNavigateFromAToB3() throws {
        // Given: Tab A의 A-1 화면
        switchToTabA()

        // When: Go to B-3 버튼 탭
        tapButton(containing: "Go to B-3")

        // Then: Tab B의 B-3 화면으로 이동
        // Tab B로 전환되었는지 확인
        verifyTabIndex(1)

        // B-3 화면의 버튼 확인
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-4)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "B-3 화면으로 이동하지 못했습니다")
    }

    func testNavigateFromAToB5() throws {
        // Given: Tab A의 A-5 화면
        switchToTabA()
        tapButton(containing: "Next (A-2)")
        tapButton(containing: "Next (A-3)")
        tapButton(containing: "Next (A-4)")
        tapButton(containing: "Next (A-5)")

        // When: Go to B-5 버튼 탭
        tapButton(containing: "Go to B-5")

        // Then: Tab B의 B-5 화면에 도달
        verifyTabIndex(1)

        // B-5는 마지막 화면이므로 Next 버튼이 없어야 함
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next")).firstMatch
        XCTAssertFalse(nextButton.exists, "B-5 화면에 도달하지 못했습니다")
    }

    // MARK: - Tab B to Tab A Tests

    func testNavigateFromBToA1() throws {
        // Given: Tab B의 B-3 화면
        switchToTabB()
        tapButton(containing: "Next (B-2)")
        tapButton(containing: "Next (B-3)")

        // When: Go to A-1 버튼 탭
        tapButton(containing: "Go to A-1")

        // Then: Tab A의 A-1 화면으로 이동
        // Tab A로 전환되었는지 확인
        verifyTabIndex(0)

        // A-1 화면의 버튼 확인
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-2)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "A-1 화면으로 이동하지 못했습니다")
    }

    func testNavigateFromBToA2() throws {
        // Given: Tab B의 B-1 화면
        switchToTabB()

        // When: Go to A-2 버튼 탭
        tapButton(containing: "Go to A-2")

        // Then: Tab A의 A-2 화면으로 이동
        verifyTabIndex(0)

        // A-2 화면의 버튼 확인
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-3)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "A-2 화면으로 이동하지 못했습니다")
    }

    func testNavigateFromBToA5() throws {
        // Given: Tab B의 B-2 화면
        switchToTabB()
        tapButton(containing: "Next (B-2)")

        // When: Go to A-5 버튼 탭
        tapButton(containing: "Go to A-5")

        // Then: Tab A의 A-5 화면으로 이동
        verifyTabIndex(0)

        // A-5는 마지막 화면이므로 Next 버튼이 없어야 함
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next")).firstMatch
        XCTAssertFalse(nextButton.exists, "A-5 화면에 도달하지 못했습니다")
    }

    func testNavigateFromB5ToA3() throws {
        // Given: Tab B의 B-5 화면
        switchToTabB()
        tapButton(containing: "Next (B-2)")
        tapButton(containing: "Next (B-3)")
        tapButton(containing: "Next (B-4)")
        tapButton(containing: "Next (B-5)")

        // When: Go to A-3 버튼 탭
        tapButton(containing: "Go to A-3")

        // Then: Tab A의 A-3 화면으로 이동
        verifyTabIndex(0)

        // A-3 화면의 버튼 확인
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-4)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "A-3 화면으로 이동하지 못했습니다")
    }

    // MARK: - Navigation Stack Preservation Tests

    func testNavigationStackIsClearedOnCrossTabNavigation() throws {
        // Given: Tab A에서 A-1 → A-2로 이동
        switchToTabA()
        tapButton(containing: "Next (A-2)")

        // When: Tab B의 B-3으로 크로스 탭 네비게이션 (A-1에서 Go to B-3 버튼 사용)
        // A-1로 돌아가서 Go to B-3 버튼 탭
        tapButton(containing: "Back")
        tapButton(containing: "Go to B-3")

        // Then: Tab B의 B-3 화면에 도달하고, 이전 Tab A의 스택은 정리됨
        verifyTabIndex(1)

        // B-3 화면 확인
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-4)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "B-3 화면으로 이동하지 못했습니다")

        // Tab A로 돌아가면 A-1 화면이어야 함 (스택이 정리되었으므로)
        switchToTabA()
        let a1NextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-2)")).firstMatch
        XCTAssertTrue(a1NextButton.waitForExistence(timeout: 3.0), "Tab A의 스택이 정리되지 않았습니다")
    }

    // MARK: - Multiple Cross Tab Navigation Tests

    func testMultipleCrossTabNavigations() throws {
        // Given: Tab A의 A-1 화면
        switchToTabA()

        // When: A → B → A → B 순서로 크로스 탭 네비게이션
        tapButton(containing: "Go to B-3")
        verifyTabIndex(1)

        // B-3에서 A-1로 이동
        tapButton(containing: "Go to A-1")
        verifyTabIndex(0)

        // A-4에서 B-1로 이동
        switchToTabA()
        tapButton(containing: "Next (A-2)")
        tapButton(containing: "Next (A-3)")
        tapButton(containing: "Next (A-4)")
        tapButton(containing: "Go to B-1")
        verifyTabIndex(1)

        // Then: Tab B의 B-1 화면에 도달
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-2)")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3.0), "B-1 화면에 도달하지 못했습니다")
    }
}
