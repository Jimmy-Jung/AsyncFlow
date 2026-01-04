//
//  NavigationFlow.swift
//  AsyncFlow
//
//  Created by jimmy on 2026. 1. 3.
//

import Foundation
import ObjectiveC

#if canImport(UIKit)
    import UIKit

    /// UINavigationController 기반 Flow의 베이스 클래스
    ///
    /// NavigationFlow는 UINavigationController를 관리하며,
    /// ViewController와 연결된 메타데이터를 자동으로 추적합니다.
    ///
    /// ## 사용 예시
    ///
    /// ```swift
    /// @MainActor
    /// final class TabAFlow: NavigationFlow {
    ///     override func navigate(to step: Step) -> FlowContributors {
    ///         guard let step = step as? TabAStep else { return .none }
    ///
    ///         switch step {
    ///         case .navigateToScreen1:
    ///             let viewModel = A_1ViewModel(depth: 0)
    ///             let viewController = A_1ViewController(viewModel: viewModel)
    ///
    ///             // Step과 Stepper 연결 (메타데이터 자동 추적)
    ///             associate(step: step, stepper: viewModel, with: viewController)
    ///
    ///             navigationController.pushViewController(viewController, animated: true)
    ///
    ///             return .one(flowContributor: .contribute(
    ///                 withNextPresentable: viewController,
    ///                 withNextStepper: viewModel
    ///             ))
    ///         }
    ///     }
    /// }
    /// ```
    @MainActor
    open class NavigationFlow: Flow {
        // MARK: - Properties

        public var root: Presentable { navigationController }

        public let navigationController: UINavigationController

        /// 메타데이터 변경 Subject
        private let metadataSubject = AsyncPassthroughSubject<[any FlowMetadata]>()

        public var metadataDidChange: AsyncStream<[any FlowMetadata]> {
            metadataSubject.stream
        }

        /// 스택 변경 시 로깅 트리거 콜백
        var onStackChanged: (() -> Void)?

        /// Navigation Delegate (strong reference로 유지)
        private var navigationDelegate: NavigationFlowDelegate?

        /// 현재 스택의 메타데이터 (ViewModel에서 자동 추출)
        public var currentStackMetadata: [any FlowMetadata] {
            navigationController.viewControllers.compactMap { vc in
                // ViewController → ViewModel(Stepper) → 메타데이터
                guard let stepper = associatedStepper(for: vc) else { return nil }
                return stepper.metadata
            }
        }

        /// 현재 스택 경로를 문자열로 반환
        public var currentStackPath: String {
            let metadata = currentStackMetadata
            guard !metadata.isEmpty else { return "" }
            return metadata.map { $0.displayName }.joined(separator: " → ")
        }

        // MARK: - Initialization

        public init(navigationController: UINavigationController? = nil) {
            if let navigationController = navigationController {
                self.navigationController = navigationController
            } else {
                self.navigationController = UINavigationController()
            }
            setupNavigationObserver()
        }

        // MARK: - Flow Protocol

        open func adapt(step: Step) async -> Step { step }

        open func navigate(to _: Step) -> FlowContributors {
            fatalError("Subclass must implement navigate(to:)")
        }

        open func metadata(for _: Step) -> (any FlowMetadata)? {
            // NavigationFlow는 Step이 아닌 ViewModel에서 메타데이터를 가져옵니다
            // currentStackMetadata를 사용하세요
            return nil
        }

        // MARK: - Helper Methods

        /// ViewController에 Step과 Stepper 연결
        ///
        /// 이 메서드를 호출하면 ViewController가 navigationController에 push/present될 때
        /// 메타데이터가 자동으로 추적됩니다.
        ///
        /// - Parameters:
        ///   - step: 현재 Step
        ///   - stepper: ViewModel (FlowStepper)
        ///   - viewController: 연결할 ViewController
        public func associate(
            step: Step,
            stepper: FlowStepper,
            with viewController: UIViewController
        ) {
            objc_setAssociatedObject(
                viewController,
                &associatedStepKey,
                StepWrapper(step: step),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )

            objc_setAssociatedObject(
                viewController,
                &associatedStepperKey,
                stepper,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }

        /// ViewController에서 Step 조회
        ///
        /// - Parameter viewController: 조회할 ViewController
        /// - Returns: 연결된 Step, 없으면 nil
        public func associatedStep(for viewController: UIViewController) -> Step? {
            (objc_getAssociatedObject(viewController, &associatedStepKey) as? StepWrapper)?.step
        }

        /// ViewController에서 Stepper 조회 (메타데이터 추출용)
        ///
        /// - Parameter viewController: 조회할 ViewController
        /// - Returns: 연결된 Stepper, 없으면 nil
        public func associatedStepper(for viewController: UIViewController) -> FlowStepper? {
            objc_getAssociatedObject(viewController, &associatedStepperKey) as? FlowStepper
        }

        // MARK: - Navigation Observer

        private func setupNavigationObserver() {
            let delegate = NavigationFlowDelegate(flow: self)
            navigationDelegate = delegate // strong reference로 유지
            navigationController.delegate = delegate
        }

        func notifyMetadataChanged() {
            Task { @MainActor in
                metadataSubject.send(currentStackMetadata)
            }
        }
    }

    // MARK: - Associated Objects

    nonisolated(unsafe) var associatedStepKey: UInt8 = 0
    nonisolated(unsafe) var associatedStepperKey: UInt8 = 0

    private class StepWrapper {
        let step: Step
        init(step: Step) {
            self.step = step
        }
    }

    // MARK: - UIViewController Extension

    public extension UIViewController {
        /// 현재 NavigationController의 스택 경로를 반환
        var navigationStackPath: String? {
            guard let navigationController = navigationController else { return nil }

            let stackPath = navigationController.viewControllers.compactMap { vc -> String? in
                guard let stepper = objc_getAssociatedObject(vc, &associatedStepperKey) as? FlowStepper else {
                    return nil
                }
                return stepper.metadata.displayName
            }.joined(separator: " → ")

            return stackPath.isEmpty ? nil : stackPath
        }
    }

    // MARK: - Delegate

    private class NavigationFlowDelegate: NSObject, UINavigationControllerDelegate {
        @MainActor weak var flow: NavigationFlow?

        init(flow: NavigationFlow) {
            self.flow = flow
            super.init()
        }

        func navigationController(
            _: UINavigationController,
            didShow _: UIViewController,
            animated _: Bool
        ) {
            // 네비게이션 완료 후 메타데이터 자동 업데이트
            flow?.notifyMetadataChanged()

            // 스택 변경 시 로깅 트리거
            flow?.onStackChanged?()
        }
    }

#endif
