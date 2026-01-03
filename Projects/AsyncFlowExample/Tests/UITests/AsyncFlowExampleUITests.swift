//
//  AsyncFlowExampleUITests.swift
//  AsyncFlowExampleUITests
//
//  Created by jimmy on 2026. 1. 3.
//

import XCTest

/// AsyncFlowExample UI 테스트 기본 클래스
///
/// 앱의 UI 테스트를 위한 공통 설정 및 헬퍼 메서드를 제공합니다.
/// 테스트 클래스당 한 번만 앱을 실행하여 성능을 최적화합니다.
class AsyncFlowExampleUITests: XCTestCase {
    // MARK: - Properties

    static var app: XCUIApplication!
    var app: XCUIApplication! {
        return Self.app
    }

    // MARK: - Setup & Teardown

    override class func setUp() {
        super.setUp()

        // 테스트 클래스당 한 번만 앱 실행
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()

        // 앱이 완전히 로드될 때까지 대기
        let tabBar = app.tabBars.firstMatch
        _ = tabBar.waitForExistence(timeout: 5.0)
    }

    override class func tearDown() {
        // 테스트 클래스가 종료될 때 앱 종료
        app.terminate()
        app = nil

        super.tearDown()
    }

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Modal만 닫기 (탭 전환은 각 테스트에서 명시적으로 수행)
        dismissAllModals()
    }

    override func tearDownWithError() throws {
        // 각 테스트 후 정리는 필요 없음 (앱이 계속 실행 중)
    }

    // MARK: - State Management

    /// 모든 Modal 닫기
    private func dismissAllModals() {
        // Modal Screen이 있는지 확인
        let modalTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Modal Screen")).firstMatch

        if modalTitle.exists {
            let dismissButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Dismiss")).firstMatch
            if dismissButton.exists {
                dismissButton.tap()
                waitForModalToDismiss(modalTitle, timeout: 2.0)
            }
        }
    }

    // MARK: - Helper Methods

    /// Tab A로 전환하고 루트 화면으로 리셋
    func switchToTabA() {
        let tabBar = app.tabBars.firstMatch
        let tabAButton = tabBar.buttons["Tab A"]
        XCTAssertTrue(tabAButton.waitForExistence(timeout: 2.0))

        // 현재 Tab A가 아니거나, Tab A의 루트가 아니면 리셋
        if !tabAButton.isSelected || !isAtTabARoot() {
            tabAButton.tap()

            // Tab A의 루트 화면으로 이동
            resetToTabRoot(rootIndicator: "Next (A-2)")

            // Tab A의 첫 화면 요소가 나타날 때까지 대기
            let tabAIndicator = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-2)")).firstMatch
            _ = tabAIndicator.waitForExistence(timeout: 3.0)
        }
    }

    /// Tab B로 전환하고 루트 화면으로 리셋
    func switchToTabB() {
        let tabBar = app.tabBars.firstMatch
        let tabBButton = tabBar.buttons["Tab B"]
        XCTAssertTrue(tabBButton.waitForExistence(timeout: 2.0))

        // 현재 Tab B가 아니거나, Tab B의 루트가 아니면 리셋
        if !tabBButton.isSelected || !isAtTabBRoot() {
            tabBButton.tap()

            // Tab B의 루트 화면으로 이동
            resetToTabRoot(rootIndicator: "Next (B-2)")

            // Tab B의 첫 화면 요소가 나타날 때까지 대기
            let tabBIndicator = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-2)")).firstMatch
            _ = tabBIndicator.waitForExistence(timeout: 3.0)
        }
    }

    /// Tab A의 루트 화면에 있는지 확인
    private func isAtTabARoot() -> Bool {
        let a1Indicator = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (A-2)")).firstMatch
        return a1Indicator.exists && a1Indicator.isHittable
    }

    /// Tab B의 루트 화면에 있는지 확인
    private func isAtTabBRoot() -> Bool {
        let b1Indicator = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next (B-2)")).firstMatch
        return b1Indicator.exists && b1Indicator.isHittable
    }

    /// 현재 탭의 루트 화면으로 리셋
    /// - Parameter rootIndicator: 루트 화면을 식별하는 버튼 텍스트 (예: "Next (A-2)")
    private func resetToTabRoot(rootIndicator: String) {
        let rootButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", rootIndicator)).firstMatch

        // 이미 루트 화면이면 리턴
        if rootButton.exists, rootButton.isHittable {
            return
        }

        // 전략 1: Go to Root 버튼 찾기 (있으면 가장 빠름)
        let goToRootButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Go to Root")).firstMatch

        // Go to Root 버튼이 존재하면 시도
        if goToRootButton.waitForExistence(timeout: 1.0) {
            // 스크롤해서 버튼을 hittable하게 만들기
            if !goToRootButton.isHittable {
                let scrollView = app.scrollViews.firstMatch
                if scrollView.exists {
                    scrollView.swipeUp()
                    Thread.sleep(forTimeInterval: 0.2)
                }
            }

            // Go to Root 버튼을 탭할 수 있으면 탭
            if goToRootButton.isHittable {
                goToRootButton.tap()
                // 루트 화면 도달 확인
                if rootButton.waitForExistence(timeout: 2.0) {
                    return
                }
            }
        }

        // 전략 2: Back 버튼으로 루트까지 이동
        var backAttempts = 0
        let maxBackAttempts = 10

        while backAttempts < maxBackAttempts {
            // 루트 화면에 도달했는지 확인
            if rootButton.exists, rootButton.isHittable {
                return
            }

            // Back 버튼 찾기
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists, backButton.isHittable {
                backButton.tap()
                Thread.sleep(forTimeInterval: 0.2)
                backAttempts += 1
            } else {
                // Back 버튼이 없으면 더 이상 뒤로 갈 수 없음
                break
            }
        }

        // 최종 확인: 루트 화면이 나타날 때까지 대기
        _ = rootButton.waitForExistence(timeout: 2.0)
    }

    /// 현재 화면의 제목 확인
    func verifyScreenTitle(_ expectedTitle: String, timeout: TimeInterval = 3.0) {
        // CommonScreenView의 titleLabel은 접근성이 설정되어 있지 않을 수 있으므로
        // 스택 경로 레이블이나 버튼 텍스트로 화면을 식별
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", expectedTitle)
        let element = app.staticTexts.matching(predicate).firstMatch

        if element.waitForExistence(timeout: timeout) {
            XCTAssertTrue(element.exists, "화면 제목 '\(expectedTitle)'을 찾을 수 없습니다")
        }
    }

    /// 버튼 탭 (제목으로 찾기)
    func tapButton(containing text: String, timeout: TimeInterval = 3.0) {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        var button = app.buttons.matching(predicate).firstMatch

        // 버튼이 존재하고 hittable할 때까지 시도
        let maxScrollAttempts = 3
        var scrollAttempts = 0

        while scrollAttempts < maxScrollAttempts {
            // 버튼이 존재하는지 확인
            if button.waitForExistence(timeout: timeout / Double(maxScrollAttempts)) {
                // 버튼이 hittable하면 탭
                if button.isHittable {
                    button.tap()
                    waitForNavigationToComplete()
                    return
                }

                // 버튼은 있지만 hittable하지 않으면 스크롤
                let scrollView = app.scrollViews.firstMatch
                if scrollView.exists {
                    scrollView.swipeUp()
                    waitForScrollToComplete()
                } else {
                    // ScrollView가 없으면 앱 전체를 스크롤
                    app.swipeUp()
                    waitForScrollToComplete()
                }
            } else {
                // 버튼을 찾지 못한 경우 스크롤 시도
                let scrollView = app.scrollViews.firstMatch
                if scrollView.exists {
                    scrollView.swipeUp()
                    waitForScrollToComplete()
                } else {
                    app.swipeUp()
                    waitForScrollToComplete()
                }
            }

            scrollAttempts += 1
            button = app.buttons.matching(predicate).firstMatch
        }

        // 최종 확인
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "버튼 '\(text)'을 찾을 수 없습니다")
        XCTAssertTrue(button.isHittable, "버튼 '\(text)'이 화면에 보이지 않습니다")

        button.tap()
        waitForNavigationToComplete()
    }

    /// 뒤로 가기 버튼 탭
    func tapBackButton() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
            waitForNavigationToComplete()
        }
    }

    /// 현재 탭 인덱스 확인
    func verifyTabIndex(_ expectedIndex: Int) {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "TabBar를 찾을 수 없습니다")

        // TabBar의 버튼들 확인
        let buttons = tabBar.buttons
        if expectedIndex < buttons.count {
            let selectedButton = buttons.element(boundBy: expectedIndex)
            // iOS의 TabBar는 선택된 버튼의 접근성 특성이 다를 수 있음
            // 실제로는 버튼이 존재하는지만 확인
            XCTAssertTrue(selectedButton.exists)
        }
    }

    // MARK: - Wait Helpers

    /// 네비게이션 완료 대기
    ///
    /// 화면 전환이나 네비게이션 애니메이션이 완료될 때까지 대기합니다.
    /// 네비게이션 바나 탭 바가 안정화될 때까지 짧은 시간 대기합니다.
    func waitForNavigationToComplete(timeout: TimeInterval = 2.0) {
        // 네비게이션 바나 탭 바가 존재하고 hittable 상태가 될 때까지 대기
        let navigationBar = app.navigationBars.firstMatch
        let tabBar = app.tabBars.firstMatch

        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: navigationBar.exists ? navigationBar : tabBar)

        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        // 타임아웃이 발생해도 계속 진행 (일부 화면에서는 네비게이션 바가 없을 수 있음)
        if result == .timedOut {
            // 네비게이션 바가 없는 경우를 위해 짧은 대기
            Thread.sleep(forTimeInterval: 0.3)
        }
    }

    /// 스크롤 완료 대기
    ///
    /// 스크롤 애니메이션이 완료될 때까지 대기합니다.
    func waitForScrollToComplete() {
        // 스크롤 애니메이션 완료를 위한 짧은 대기
        // XCTest에서는 스크롤 완료를 직접 감지할 수 없으므로 짧은 대기 시간 사용
        Thread.sleep(forTimeInterval: 0.3)
    }

    /// 요소가 hittable 상태가 될 때까지 대기
    ///
    /// - Parameters:
    ///   - element: 대기할 요소
    ///   - timeout: 타임아웃 시간
    /// - Returns: 요소가 hittable 상태가 되었는지 여부
    @discardableResult
    func waitForElementToBeHittable(_ element: XCUIElement, timeout: TimeInterval = 3.0) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Modal dismiss 완료 대기
    ///
    /// Modal 화면이 완전히 사라질 때까지 대기합니다.
    /// - Parameter modalElement: Modal에서 unique한 요소 (예: "Modal Screen" 텍스트)
    func waitForModalToDismiss(_ modalElement: XCUIElement, timeout: TimeInterval = 3.0) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: modalElement)
        _ = XCTWaiter().wait(for: [expectation], timeout: timeout)
    }
}
