//
//  AppDelegate.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

// MARK: - SceneDelegate

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    let coordinator = FlowCoordinator()

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Window 생성
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // 네비게이션 이벤트 로깅 (개발 환경)
        #if DEBUG
            Task {
                for await event in coordinator.didNavigate {
                    print("✅ [\(event.flowType)] → \(event.stepDescription)")
                }
            }
        #endif

        // App Flow 시작
        let appFlow = AppFlow(window: window)
        let appStepper = OneStepper(MovieStep.appLaunch)
        coordinator.coordinate(flow: appFlow, with: appStepper)
    }
}
