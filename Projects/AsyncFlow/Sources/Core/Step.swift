//
//  Step.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// 네비게이션 의도를 표현하는 프로토콜
///
/// Step은 네비게이션 상태나 의도를 나타냅니다.
/// 주로 enum으로 구현하며, 화면 전환에 필요한 데이터를 연관값으로 전달할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// enum MovieStep: Step {
///     case movieList
///     case movieDetail(id: Int)
///     case castDetail(id: Int)
///     case unauthorized
/// }
/// ```
///
/// ## 설계 원칙
///
/// Step은 네비게이션 독립적이어야 합니다:
/// - ❌ `showMovieDetail(id: Int)` - 특정 화면 표시를 강제
/// - ✅ `movieDetail(id: Int)` - 의도만 표현, Flow가 표시 방법 결정
///
/// 이를 통해 같은 Step이라도 Flow에 따라 다르게 표현될 수 있습니다.
/// (예: iPad에서는 SplitView, iPhone에서는 Push)
public protocol Step: Sendable {}

/// 아무 네비게이션도 트리거하지 않는 Step
///
/// NoneStep은 FlowCoordinator에 의해 필터링되어 navigate(to:)가 호출되지 않습니다.
/// adapt(step:)에서 특정 Step을 무시하고 싶을 때 반환할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// func adapt(step: Step) async -> Step? {
///     switch step {
///     case MovieStep.unauthorized:
///         // 권한이 없으면 네비게이션 취소
///         return NoneStep()
///     default:
///         return step
///     }
/// }
/// ```
public struct NoneStep: Step, Equatable {
    public init() {}
}
