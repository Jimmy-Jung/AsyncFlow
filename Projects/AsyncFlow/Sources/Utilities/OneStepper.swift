//
//  OneStepper.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// 초기 Step 하나만 방출하는 Stepper
///
/// Flow를 시작할 때 초기 Step을 전달하는 용도로 사용합니다.
///
/// ## 사용 예시
///
/// ```swift
/// // AppDelegate에서
/// let appFlow = AppFlow(window: window)
/// let appStepper = OneStepper(withSingleStep: AppStep.launch)
/// coordinator.coordinate(flow: appFlow, with: appStepper)
/// ```
///
/// ```swift
/// // 자식 Flow 시작 시
/// func navigate(to step: Step) -> FlowContributors {
///     guard let step = step as? AppStep else { return .none }
///
///     switch step {
///     case .settings:
///         let settingsFlow = SettingsFlow()
///         let settingsStepper = OneStepper(withSingleStep: SettingsStep.main)
///
///         Flows.use(settingsFlow, when: .ready) { [weak self] root in
///             self?.navigationController.present(root, animated: true)
///         }
///
///         return .one(flowContributor: .contribute(
///             withNextPresentable: settingsFlow,
///             withNextStepper: settingsStepper
///         ))
///     }
/// }
/// ```
@MainActor
public final class OneStepper: FlowStepper {
    public let steps = AsyncReplaySubject<Step>(bufferSize: 1)

    private let singleStep: Step

    /// 초기 Step을 반환
    public var initialStep: Step {
        singleStep
    }

    /// OneStepper 초기화
    ///
    /// - Parameter singleStep: 방출할 초기 Step
    public init(withSingleStep singleStep: Step) {
        self.singleStep = singleStep
    }
}

/// 기본 Stepper
///
/// NoneStep을 초기 Step으로 방출합니다.
/// Flow를 시작할 때 특별한 초기 Step이 필요 없을 때 사용합니다.
@MainActor
public final class DefaultStepper: FlowStepper {
    public let steps = AsyncReplaySubject<Step>(bufferSize: 1)

    public var initialStep: Step {
        NoneStep()
    }

    public init() {}
}
