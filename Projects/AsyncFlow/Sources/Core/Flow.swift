//
//  Flow.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

#if canImport(UIKit)
    import UIKit
#endif

/// 네비게이션 영역을 정의하는 프로토콜
///
/// Flow는 앱의 특정 영역(예: 영화 목록, 설정 화면)에서의 네비게이션을 담당합니다.
/// Step을 받아 실제 네비게이션 액션(화면 전환, Flow 시작 등)으로 변환합니다.
///
/// ## 사용 예시
///
/// ```swift
/// final class MovieFlow: Flow {
///     typealias StepType = MovieStep
///
///     var root: any Presentable { navigationController }
///     private let navigationController = UINavigationController()
///     private let services: AppServices
///
///     init(services: AppServices) {
///         self.services = services
///     }
///
///     func navigate(to step: MovieStep) async -> FlowContributors {
///         switch step {
///         case .movieList:
///             return navigateToMovieList()
///         case .movieDetail(let id):
///             return navigateToMovieDetail(id: id)
///         }
///     }
///
///     private func navigateToMovieList() -> FlowContributors {
///         let viewModel = MovieListViewModel()
///         let viewController = MovieListViewController(viewModel: viewModel)
///         navigationController.pushViewController(viewController, animated: true)
///
///         return .one(.contribute(presentable: viewController, stepper: viewModel))
///     }
/// }
/// ```
///
/// ## 책임
///
/// 1. **UIViewController 생성 및 표시**: DI 컨테이너 역할
/// 2. **자식 Flow 시작**: TabBar, Modal Flow 등
/// 3. **Step 필터링**: 권한 체크, 로그인 확인 등
@MainActor
public protocol Flow: Presentable {
    /// Step의 타입
    associatedtype StepType: Step

    /// Flow의 루트 Presentable
    ///
    /// 보통 UINavigationController, UITabBarController 등이 됩니다.
    var root: any Presentable { get }

    /// Step을 네비게이션 액션으로 변환
    ///
    /// - Parameter step: 처리할 Step
    /// - Returns: 다음 Stepper와 Presentable을 포함하는 FlowContributors
    func navigate(to step: StepType) async -> FlowContributors<StepType>

    /// Step 적응 (필터링/변환)
    ///
    /// Step이 `navigate(to:)`로 전달되기 전에 호출됩니다.
    /// 권한 체크, 로그인 확인 등의 로직을 구현할 수 있습니다.
    ///
    /// - Parameter step: 적응할 Step
    /// - Returns: 적응된 Step (nil이면 네비게이션 취소)
    ///
    /// ## 사용 예시
    ///
    /// ```swift
    /// func adapt(step: MovieStep) async -> MovieStep? {
    ///     switch step {
    ///     case .movieDetail:
    ///         // 권한 체크
    ///         return await PermissionManager.isAuthorized() ? step : .unauthorized
    ///     default:
    ///         return step
    ///     }
    /// }
    /// ```
    func adapt(step: StepType) async -> StepType?
}

// MARK: - Default Implementation

public extension Flow {
    /// 기본 구현: Step을 그대로 반환
    func adapt(step: StepType) async -> StepType? {
        return step
    }

    /// Presentable 프로토콜 요구사항: Flow 자체가 Presentable
    var viewController: PlatformViewController {
        root.viewController
    }

    var isPresented: Bool {
        root.isPresented
    }

    var onDismissed: AsyncStream<Void> {
        root.onDismissed
    }
}
