//
//  AppDelegate.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 1.
//

import AsyncFlow
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Properties

    var window: UIWindow?
    let coordinator = FlowCoordinator()
    var appFlow: AppFlow?

    // MARK: - UIApplicationDelegate

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // UI 테스트 모드 확인
        let isUITesting = CommandLine.arguments.contains("-UITestMode")
        let shouldResetState = ProcessInfo.processInfo.environment["RESET_STATE"] == "true"

        if isUITesting && shouldResetState {
            // 테스트 모드: 싱글톤 상태 초기화
            NavigationStackViewModel.shared.resetToRoot()
            print("🧪 UI Test Mode: State reset")
        }

        // Window 생성
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        // AppFlow 생성
        let appFlow = AppFlow(window: window)
        self.appFlow = appFlow

        // FlowCoordinator 시작 (네비게이션은 UINavigationControllerDelegate에서 처리)
        coordinator.coordinate(flow: appFlow, with: OneStepper(withSingleStep: DemoStep.screenA))

        return true
    }
}
