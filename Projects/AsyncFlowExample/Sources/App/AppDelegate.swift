//
//  AppDelegate.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import UIKit
import AsyncFlow

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let coordinator = FlowCoordinator()
    var appFlow: AppFlow?  // Strong reference 유지
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let services = AppServices(
            authService: AuthService(),
            permissionService: PermissionService(),
            deepLinkService: DeepLinkService(),
            analyticsService: AnalyticsService()
        )
        
        let appFlow = AppFlow(
            window: window!,
            services: services,
            coordinator: coordinator
        )
        self.appFlow = appFlow  // Strong reference 저장
        
        // 네비게이션 이벤트 모니터링
        Task {
            for await event in coordinator.willNavigate {
                print("🚀 Will Navigate: \(event.flowType) -> \(event.stepDescription)")
                services.analyticsService.trackNavigation(event)
            }
        }
        
        Task {
            for await event in coordinator.didNavigate {
                print("✅ Did Navigate: \(event.flowType) -> \(event.stepDescription)")
            }
        }
        
        // AppFlow 시작
        let appStepper = OneStepper(withSingleStep: AppStep.launch)
        coordinator.coordinate(flow: appFlow, with: appStepper)
        
        return true
    }
    
    // Deep Link 처리
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("🔗 Deep Link Received: \(url.absoluteString)")
        // TODO: Deep Link를 AppFlow에 전달
        return true
    }
}
