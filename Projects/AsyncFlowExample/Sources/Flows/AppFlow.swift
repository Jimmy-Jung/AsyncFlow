//
//  AppFlow.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import UIKit

@MainActor
final class AppFlow: Flow {
    var root: any Presentable { window }
    
    private let window: UIWindow
    private let services: AppServices
    private let coordinator: FlowCoordinator
    private var mainFlow: MainFlow?
    private var authFlow: AuthFlow?
    
    init(window: UIWindow, services: AppServices, coordinator: FlowCoordinator) {
        self.window = window
        self.services = services
        self.coordinator = coordinator
    }
    
    func navigate(to step: Step) -> FlowContributors {
        guard let appStep = step as? AppStep else { return .none }
        switch appStep {
        case .launch:
            return navigateToLaunch()
            
        case .onboarding:
            return navigateToOnboarding()
            
        case .main:
            return navigateToMain()
            
        case .deepLink(let url):
            return navigateToDeepLink(url)
            
        case .auth(let authStep):
            switch authStep {
            case .loginRequired, .registerRequired, .forgotPassword:
                return navigateToAuth(authStep)
            case .loginSuccess, .registerSuccess:
                // 콜백으로 처리됨
                return .none
            case .loginCancelled:
                return .none
            }
            
        case .settings(let settingsStep):
            if case .logout = settingsStep {
                return navigateToLogout()
            }
            return .none
            
        case .dashboard:
            // DashboardFlow에서 처리
            return .none
        }
    }
    
    private func navigateToLaunch() -> FlowContributors {
        if services.authService.isLoggedIn {
            return .one(flowContributor: .forwardToCurrentFlow(withStep: AppStep.main))
        } else {
            return .one(flowContributor: .forwardToCurrentFlow(withStep: AppStep.auth(.loginRequired)))
        }
    }
    
    private func navigateToOnboarding() -> FlowContributors {
        return .none
    }
    
    private func navigateToMain() -> FlowContributors {
        let mainFlow = MainFlow(services: services, coordinator: coordinator)
        self.mainFlow = mainFlow
        
        window.rootViewController = mainFlow.root.viewController
        window.makeKeyAndVisible()
        
        return .one(flowContributor: .contribute(
            withNextPresentable: mainFlow,
            withNextStepper: OneStepper(withSingleStep: AppStep.main)
        ))
    }
    
    // MARK: - Private
    
    private func navigateToAuth(_ authStep: AppStep.Auth) -> FlowContributors {
        // 이미 authFlow가 표시 중이면 무시
        if authFlow != nil {
            return .none
        }
        
        // AuthFlow 생성
        let authFlow = AuthFlow(services: services)
        self.authFlow = authFlow
        
        window.rootViewController = authFlow.root.viewController
        window.makeKeyAndVisible()
        
        // AuthFlow를 자식 Flow로 coordinate (자동으로 자식 FlowCoordinator 생성)
        return .one(flowContributor: .contribute(
            withNextPresentable: authFlow,
            withNextStepper: OneStepper(withSingleStep: AppStep.auth(authStep))
        ))
    }
    
    private func navigateToLogout() -> FlowContributors {
        services.authService.logout()
        authFlow = nil
        mainFlow = nil
        
        return .one(flowContributor: .forwardToCurrentFlow(withStep: AppStep.auth(.loginRequired)))
    }
    
    private func navigateToDeepLink(_ url: URL) -> FlowContributors {
        guard let deepLink = services.deepLinkService.parseDeepLink(url) else {
            return .none
        }
        
        services.analyticsService.trackAction("deep_link", properties: ["url": url.absoluteString])
        
        switch deepLink {
        case .dashboard:
            return .one(flowContributor: .forwardToCurrentFlow(withStep: AppStep.main))
            
        case .settingsProfile:
            if mainFlow == nil {
                _ = navigate(to: AppStep.main)
            }
            return .one(flowContributor: .forwardToCurrentFlow(withStep: AppStep.settings(.profile)))
            
        case .settingsNotifications:
            if mainFlow == nil {
                _ = navigate(to: AppStep.main)
            }
            return .one(flowContributor: .forwardToCurrentFlow(withStep: AppStep.settings(.notifications)))
            
        case .feature(let id):
            if let feature = Feature.mockFeatures.first(where: { $0.id == id }) {
                return .one(flowContributor: .forwardToCurrentFlow(withStep: AppStep.dashboard(.featureDetail(feature))))
            }
            return .none
        }
    }
}
