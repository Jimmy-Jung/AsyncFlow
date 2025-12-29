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
/// let appStepper = OneStepper(AppStep.launch)
/// coordinator.coordinate(flow: appFlow, with: appStepper)
/// ```
///
/// ```swift
/// // 자식 Flow 시작 시
/// func navigateToSettings() -> FlowContributors {
///     let settingsFlow = SettingsFlow()
///     let settingsStepper = OneStepper(SettingsStep.settings)
///
///     return .one(.contribute(presentable: settingsFlow, stepper: settingsStepper))
/// }
/// ```
@MainActor
public final class OneStepper<S: Step>: Stepper {
    public typealias StepType = S

    @StepEmitter public var stepEmitter: StepEmitter<S>

    private let initialStep: S

    public var steps: AsyncStream<S> {
        AsyncStream { continuation in
            continuation.yield(initialStep)
        }
    }

    /// OneStepper 초기화
    ///
    /// - Parameter step: 방출할 초기 Step
    public init(_ step: S) {
        initialStep = step
    }
}
