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
