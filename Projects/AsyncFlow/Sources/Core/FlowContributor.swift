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
public enum FlowContributor<S: Step> {
    /// Presentable과 Stepper를 연결
    case contribute(presentable: any Presentable, stepper: any Stepper<S>)

    /// 더 이상 네비게이션 없음
    case none
}

/// 여러 FlowContributor를 묶는 타입
public enum FlowContributors<S: Step> {
    /// 아무 Contributor도 없음
    case none

    /// 단일 Contributor
    case one(FlowContributor<S>)

    /// 여러 Contributor
    case multiple([FlowContributor<S>])
}

// MARK: - Convenience Extensions

public extension FlowContributors {
    /// 여러 Contributor를 가변 인자로 생성
    static func multiple(_ contributors: FlowContributor<S>...) -> FlowContributors<S> {
        .multiple(contributors)
    }
}
