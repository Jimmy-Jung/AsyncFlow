//
//  FlowContributor.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// 다음 Stepper와 Presentable을 연결하는 타입
///
/// FlowContributor는 `navigate(to:)` 함수의 반환값으로 사용되며,
/// 어떤 Presentable이 어떤 Stepper의 Step을 처리할지 정의합니다.
///
/// ## Cases
///
/// - `contribute`: Presentable과 Stepper를 연결하여 해당 Flow에 기여
/// - `forwardToCurrentFlow`: 현재 Flow에 Step을 즉시 전달
/// - `forwardToParentFlow`: 부모 Flow에 Step을 전달
public enum FlowContributor {
    /// Presentable과 Stepper를 연결하여 현재 Flow에 기여
    ///
    /// - Parameters:
    ///   - withNextPresentable: 다음에 표시될 Presentable
    ///   - withNextStepper: Step을 방출할 Stepper
    ///   - allowStepWhenNotPresented: Presentable이 표시되지 않아도 Step 허용 (기본값: false)
    ///   - allowStepWhenDismissed: Presentable이 dismiss되어도 Step 허용 (기본값: false)
    case contribute(
        withNextPresentable: Presentable,
        withNextStepper: FlowStepper,
        allowStepWhenNotPresented: Bool = false,
        allowStepWhenDismissed: Bool = false
    )

    /// 현재 Flow에 Step을 즉시 전달
    ///
    /// navigate(to:) 내에서 다른 Step을 트리거하고 싶을 때 사용합니다.
    ///
    /// ## 사용 예시
    ///
    /// ```swift
    /// func navigate(to step: Step) -> FlowContributors {
    ///     guard let step = step as? MovieStep else { return .none }
    ///
    ///     switch step {
    ///     case .loginRequired:
    ///         // 로그인 성공 후 홈으로 이동
    ///         return .one(.forwardToCurrentFlow(withStep: MovieStep.home))
    ///     }
    /// }
    /// ```
    case forwardToCurrentFlow(withStep: Step)

    /// 부모 Flow에 Step을 전달
    ///
    /// 자식 Flow에서 부모 Flow의 네비게이션을 트리거하고 싶을 때 사용합니다.
    ///
    /// ## 사용 예시
    ///
    /// ```swift
    /// func navigate(to step: Step) -> FlowContributors {
    ///     guard let step = step as? SettingsStep else { return .none }
    ///
    ///     switch step {
    ///     case .logout:
    ///         // 부모 Flow에 로그아웃 알림
    ///         return .one(.forwardToParentFlow(withStep: AppStep.logout))
    ///     }
    /// }
    /// ```
    case forwardToParentFlow(withStep: Step)
}

// MARK: - Convenience

public extension FlowContributor {
    /// Presentable과 Stepper가 동일한 객체일 때 사용하는 편의 메서드
    ///
    /// - Parameter withNext: Presentable과 Stepper를 동시에 구현한 객체
    /// - Returns: .contribute FlowContributor
    static func contribute(withNext nextPresentableAndStepper: Presentable & FlowStepper) -> FlowContributor {
        .contribute(
            withNextPresentable: nextPresentableAndStepper,
            withNextStepper: nextPresentableAndStepper
        )
    }
}

/// 여러 FlowContributor를 묶는 타입
///
/// ## Cases
///
/// - `none`: 아무 Contributor도 없음 (네비게이션 종료)
/// - `one`: 단일 Contributor
/// - `multiple`: 여러 Contributor
/// - `end`: 현재 Flow 종료 및 부모 Flow에 Step 전달
public enum FlowContributors {
    /// 아무 Contributor도 없음
    ///
    /// 이 Step에 대한 추가 네비게이션이 없음을 나타냅니다.
    case none

    /// 단일 Contributor
    case one(flowContributor: FlowContributor)

    /// 여러 Contributor
    ///
    /// 하나의 Step에 대해 여러 Presentable/Stepper가 기여할 때 사용합니다.
    /// (예: TabBarController의 여러 탭)
    case multiple(flowContributors: [FlowContributor])

    /// 현재 Flow 종료 및 부모 Flow에 Step 전달
    ///
    /// 자식 Flow가 완료되어 dismiss될 때 사용합니다.
    /// 연결된 모든 자식 FlowCoordinator가 정리되고,
    /// 부모 Flow에 지정된 Step이 전달됩니다.
    ///
    /// ## 사용 예시
    ///
    /// ```swift
    /// func navigate(to step: Step) -> FlowContributors {
    ///     guard let step = step as? OnboardingStep else { return .none }
    ///
    ///     switch step {
    ///     case .complete:
    ///         return .end(forwardToParentFlowWithStep: AppStep.onboardingComplete)
    ///     }
    /// }
    /// ```
    case end(forwardToParentFlowWithStep: Step)
}

// MARK: - FlowContributors Convenience

public extension FlowContributors {
    /// 여러 FlowContributor를 Variadic 파라미터로 받는 편의 메서드
    static func multiple(_ contributors: FlowContributor...) -> FlowContributors {
        .multiple(flowContributors: contributors)
    }
}
