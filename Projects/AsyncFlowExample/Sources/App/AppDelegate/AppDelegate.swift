//
//  AppDelegate.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Properties

    var window: UIWindow?
    private var coordinator: FlowCoordinator?
    private var appFlow: AppFlow?

    // MARK: - Application Lifecycle

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Window 생성
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        // AppFlow 초기화
        let appFlow = AppFlow(window: window)
        self.appFlow = appFlow

        // FlowCoordinator 초기화 (로깅 활성화)
        let logger = ConsoleFlowLogger(style: .simple)
        let coordinator = FlowCoordinator(logger: logger)
        self.coordinator = coordinator

        // Flow 시작
        coordinator.coordinate(
            flow: appFlow,
            with: OneStepper(withSingleStep: AppStep.appDidStart)
        )

        return true
    }
}
