//
//  Presentable.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

#if canImport(UIKit)
    import UIKit

    public typealias PlatformViewController = UIViewController
#elseif canImport(AppKit)
    import AppKit

    public typealias PlatformViewController = NSViewController
#endif

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
/// func navigate(to step: MovieStep) async -> FlowContributors {
///     let viewController = MovieDetailViewController()
///     navigationController.pushViewController(viewController, animated: true)
///
///     // viewController는 Presentable을 준수
///     return .one(.contribute(presentable: viewController, stepper: viewModel))
/// }
/// ```
@MainActor
public protocol Presentable: AnyObject {
    /// 실제 표시될 ViewController
    var viewController: PlatformViewController { get }

    /// 현재 화면에 표시 중인지 여부
    var isPresented: Bool { get }

    /// Dismiss 되었을 때 알림을 받는 스트림
    var onDismissed: AsyncStream<Void> { get }

    /// Dismiss 후에도 Step 처리를 허용할지 여부
    ///
    /// - `true`: Dismiss 되어도 Step 처리 (기본값)
    /// - `false`: Dismiss 되면 Step 무시
    var allowStepWhenDismissed: Bool { get }
}

// MARK: - Default Implementation

public extension Presentable {
    /// 기본적으로 Dismiss 후에도 Step 처리 허용
    var allowStepWhenDismissed: Bool { true }
}
