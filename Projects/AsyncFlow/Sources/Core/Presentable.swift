//
//  Presentable.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import UIKit

public typealias PlatformViewController = UIViewController

/// 화면에 표시될 수 있는 것을 추상화하는 프로토콜
///
/// Presentable은 UIViewController나 Flow처럼 화면에 표시될 수 있는 것을 나타냅니다.
///
/// ## 구현체
///
/// - `UIViewController`: extension으로 자동 구현
/// - `Flow`: 자식 Flow를 표시할 때 사용
///
/// ## 사용 예시
///
/// ```swift
/// func navigate(to step: Step) -> FlowContributors {
///     let viewController = MovieDetailViewController()
///     navigationController.pushViewController(viewController, animated: true)
///
///     // viewController는 Presentable을 준수
///     return .one(.contribute(withNextPresentable: viewController, withNextStepper: viewModel))
/// }
/// ```
@MainActor
public protocol Presentable: AnyObject {
    /// Presentable이 표시될 때 true를 방출하는 스트림
    ///
    /// RxFlow의 rxVisible과 동일한 역할입니다.
    /// 기본적으로 Stepper의 Step은 이 스트림이 true일 때만 처리됩니다.
    var isVisibleStream: AsyncStream<Bool> { get }

    /// Presentable이 dismiss될 때 알림을 받는 스트림
    ///
    /// RxFlow의 rxDismissed와 동일한 역할입니다.
    /// 이 스트림에서 값이 방출되면 연결된 Stepper의 구독이 해제됩니다.
    var onDismissed: AsyncStream<Void> { get }
}

// MARK: - Convenience Extension

public extension Presentable {
    /// Presentable을 UIViewController로 변환
    ///
    /// UIViewController를 직접 다루어야 할 때 사용합니다.
    var viewController: PlatformViewController? {
        self as? PlatformViewController
    }
}
