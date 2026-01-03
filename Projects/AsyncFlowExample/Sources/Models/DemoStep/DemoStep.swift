//
//  DemoStep.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow

// MARK: - AppStep

/// 앱 레벨 네비게이션 Step
enum AppStep: Step, Equatable {
    /// 앱 시작
    case appDidStart

    /// Tab A로 전환 + 화면 이동
    case switchToTabAScreen1
    case switchToTabAScreen2
    case switchToTabAScreen3
    case switchToTabAScreen5

    /// Tab B로 전환 + 화면 이동
    case switchToTabBScreen1
    case switchToTabBScreen3
    case switchToTabBScreen5
}

// MARK: - TabAStep

/// Tab A 네비게이션 Step
enum TabAStep: Step, Equatable {
    /// 화면 이동
    case navigateToScreen1
    case navigateToScreen2
    case navigateToScreen3
    case navigateToScreen4
    case navigateToScreen5

    /// 뒤로 가기
    case popViewController(count: Int = 1)

    /// 루트로 이동
    case popToRoot
}

// MARK: - TabBStep

/// Tab B 네비게이션 Step
enum TabBStep: Step, Equatable {
    /// 화면 이동
    case navigateToScreen1
    case navigateToScreen2
    case navigateToScreen3
    case navigateToScreen4
    case navigateToScreen5

    /// 뒤로 가기
    case popViewController(count: Int = 1)

    /// 루트로 이동
    case popToRoot
}

// MARK: - ModalStep

/// Modal 네비게이션 Step
enum ModalStep: Step, Equatable {
    /// Modal Present
    case presentModal

    /// Modal Dismiss
    case dismissModal
}
