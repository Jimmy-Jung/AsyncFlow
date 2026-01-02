//
//  Flow.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation
import ObjectiveC

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
///     var root: Presentable { navigationController }
///     private let navigationController = UINavigationController()
///     private let services: AppServices
///
///     init(services: AppServices) {
///         self.services = services
///     }
///
///     func navigate(to step: Step) -> FlowContributors {
///         guard let step = step as? MovieStep else { return .none }
///
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
///         return .one(flowContributor: .contribute(
///             withNextPresentable: viewController,
///             withNextStepper: viewModel
///         ))
///     }
/// }
/// ```
///
/// ## 책임
///
/// 1. UIViewController 생성 및 표시: DI 컨테이너 역할
/// 2. 자식 Flow 시작: TabBar, Modal Flow 등
/// 3. Step 필터링: adapt(step:)을 통한 권한 체크, 로그인 확인 등
@MainActor
public protocol Flow: AnyObject, Presentable {
    /// Flow의 루트 Presentable
    ///
    /// 보통 UINavigationController, UITabBarController 등이 됩니다.
    /// 이 프로퍼티는 항상 동일한 인스턴스를 반환해야 합니다.
    var root: Presentable { get }

    /// Step 적응 (필터링/변환)
    ///
    /// Step이 `navigate(to:)`로 전달되기 전에 호출됩니다.
    /// 권한 체크, 로그인 확인 등의 로직을 구현할 수 있습니다.
    ///
    /// - Parameter step: 적응할 Step
    /// - Returns: 적응된 Step (NoneStep을 반환하면 네비게이션 취소)
    ///
    /// ## 사용 예시
    ///
    /// ```swift
    /// func adapt(step: Step) async -> Step {
    ///     guard let movieStep = step as? MovieStep else { return step }
    ///
    ///     switch movieStep {
    ///     case .movieDetail:
    ///         // 권한 체크
    ///         if await PermissionManager.isAuthorized() {
    ///             return step
    ///         } else {
    ///             return MovieStep.unauthorized
    ///         }
    ///     default:
    ///         return step
    ///     }
    /// }
    /// ```
    func adapt(step: Step) async -> Step

    /// Step을 네비게이션 액션으로 변환
    ///
    /// - Parameter step: 처리할 Step
    /// - Returns: 다음 Stepper와 Presentable을 포함하는 FlowContributors
    func navigate(to step: Step) -> FlowContributors
}

// MARK: - Default Implementation

public extension Flow {
    func adapt(step: Step) async -> Step { step }

    var isVisibleStream: AsyncStream<Bool> { root.isVisibleStream }
    var onDismissed: AsyncStream<Void> { root.onDismissed }
}

// MARK: - Flow Ready Subject

private var flowReadySubjectKey: UInt8 = 0

extension Flow {
    /// Flow가 준비되었을 때 true를 방출하는 Subject
    ///
    /// 자식 Flow들이 모두 준비되면 true를 방출합니다.
    /// AsyncReplaySubject를 사용하여 구독 전 값도 받을 수 있습니다.
    var flowReadySubject: AsyncReplaySubject<Bool> {
        if let subject = objc_getAssociatedObject(self, &flowReadySubjectKey) as? AsyncReplaySubject<Bool> {
            return subject
        }

        let newSubject = AsyncReplaySubject<Bool>(bufferSize: 1)
        objc_setAssociatedObject(self, &flowReadySubjectKey, newSubject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return newSubject
    }

    /// Flow가 준비되었을 때 완료되는 스트림
    var flowReady: AsyncStream<Bool> {
        flowReadySubject.stream
    }
}
