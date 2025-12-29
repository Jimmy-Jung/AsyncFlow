# AsyncFlowExample 앱 설계 문서 (개정판)

> 원본 설계의 타입 문제와 누락된 구현을 수정한 버전입니다.

## 주요 수정 사항

1. **CompositeStepper 제거**: TabBar Flow에서 각 Flow를 독립적으로 coordinate
2. **누락된 타입 추가**: AppServices, Feature, User 등
3. **Flow emit() 오류 수정**: Flow는 Stepper가 아니므로 emit() 사용 불가
4. **AuthFlow 구현 추가**: 완전한 인증 Flow
5. **UIWindow Presentable 확장 추가**

---

## 수정된 MainFlow 구현

### MainFlow.swift (수정)

```swift
import AsyncFlow
import SwiftUI
import UIKit

@MainActor
final class MainFlow: Flow {
    typealias StepType = AppStep
    
    var root: any Presentable { tabBarController }
    private let tabBarController = UITabBarController()
    private let services: AppServices
    private let coordinator: FlowCoordinator  // ← coordinator 전달받기
    
    private var dashboardFlow: DashboardFlow?
    private var settingsFlow: SettingsFlow?
    
    init(services: AppServices, coordinator: FlowCoordinator) {
        self.services = services
        self.coordinator = coordinator
    }
    
    func navigate(to step: AppStep) async -> FlowContributors<AppStep> {
        switch step {
        case .main:
            return navigateToMain()
        case let .dashboardRequired(dashboardStep):
            return navigateToDashboard(dashboardStep)
        case let .settingsRequired(settingsStep):
            return navigateToSettings(settingsStep)
        default:
            return .none
        }
    }
    
    private func navigateToMain() -> FlowContributors<AppStep> {
        // Dashboard Flow
        let dashboardFlow = DashboardFlow(services: services)
        dashboardFlow.root.viewController.tabBarItem = UITabBarItem(
            title: "Dashboard",
            image: UIImage(systemName: "chart.bar"),
            tag: 0
        )
        
        // Settings Flow
        let settingsFlow = SettingsFlow(services: services)
        settingsFlow.root.viewController.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gear"),
            tag: 1
        )
        
        self.dashboardFlow = dashboardFlow
        self.settingsFlow = settingsFlow
        
        tabBarController.viewControllers = [
            dashboardFlow.root.viewController,
            settingsFlow.root.viewController
        ]
        
        // 각 Flow를 독립적으로 coordinate
        coordinator.coordinate(
            flow: dashboardFlow,
            with: OneStepper(DashboardStep.home)
        )
        
        coordinator.coordinate(
            flow: settingsFlow,
            with: OneStepper(SettingsStep.settings)
        )
        
        return .none
    }
    
    private func navigateToDashboard(_ step: DashboardStep) -> FlowContributors<AppStep> {
        tabBarController.selectedIndex = 0
        dashboardFlow?.navigate(to: step)
        return .none
    }
    
    private func navigateToSettings(_ step: SettingsStep) -> FlowContributors<AppStep> {
        tabBarController.selectedIndex = 1
        settingsFlow?.navigate(to: step)
        return .none
    }
}
```

---

## 추가 타입 정의

### AppServices.swift

```swift
import Foundation

struct AppServices: Sendable {
    let authService: AuthService
    let permissionService: PermissionService
    let deepLinkService: DeepLinkService
    let analyticsService: AnalyticsService
}
```

### Feature.swift

```swift
import Foundation

struct Feature: Equatable, Sendable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let requiresPermission: Bool
    
    static var mockFeatures: [Feature] {
        [
            Feature(
                id: UUID(),
                name: "Camera Scanner",
                description: "QR 코드 스캔 기능",
                icon: "camera",
                requiresPermission: true
            ),
            Feature(
                id: UUID(),
                name: "Location Tracker",
                description: "위치 추적 기능",
                icon: "location",
                requiresPermission: true
            ),
            Feature(
                id: UUID(),
                name: "Data Sync",
                description: "데이터 동기화",
                icon: "arrow.triangle.2.circlepath",
                requiresPermission: false
            ),
            Feature(
                id: UUID(),
                name: "Notifications",
                description: "푸시 알림 설정",
                icon: "bell",
                requiresPermission: true
            )
        ]
    }
}
```

### User.swift

```swift
import Foundation

struct User: Equatable, Sendable {
    let id: UUID
    let name: String
    let email: String
    let avatarURL: URL?
}
```

---

## AuthFlow 구현

### AuthFlow.swift

```swift
import AsyncFlow
import UIKit
import SwiftUI

@MainActor
final class AuthFlow: Flow {
    typealias StepType = AuthStep
    
    var root: any Presentable { navigationController }
    private let navigationController = UINavigationController()
    private let services: AppServices
    
    init(services: AppServices) {
        self.services = services
    }
    
    func navigate(to step: AuthStep) async -> FlowContributors<AuthStep> {
        switch step {
        case .login:
            return navigateToLogin()
            
        case .register:
            return navigateToRegister()
            
        case .forgotPassword:
            return navigateToForgotPassword()
            
        case .loginSuccess:
            // AppFlow에서 처리
            return .none
            
        case .loginCancelled:
            navigationController.dismiss(animated: true)
            return .none
        }
    }
    
    private func navigateToLogin() -> FlowContributors<AuthStep> {
        let viewModel = LoginViewModel(authService: services.authService)
        let view = LoginView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = "Login"
        
        navigationController.setViewControllers([viewController], animated: false)
        
        return .one(.contribute(presentable: viewController, stepper: viewModel))
    }
    
    private func navigateToRegister() -> FlowContributors<AuthStep> {
        let viewModel = RegisterViewModel(authService: services.authService)
        let viewController = RegisterViewController(viewModel: viewModel)
        viewController.title = "Register"
        
        navigationController.pushViewController(viewController, animated: true)
        
        return .one(.contribute(presentable: viewController, stepper: viewModel))
    }
    
    private func navigateToForgotPassword() -> FlowContributors<AuthStep> {
        // 간단한 Alert로 처리
        let alert = UIAlertController(
            title: "비밀번호 찾기",
            message: "이메일을 입력하세요",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "email@example.com"
            textField.keyboardType = .emailAddress
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "전송", style: .default) { _ in
            // 비밀번호 재설정 이메일 전송
        })
        
        navigationController.present(alert, animated: true)
        
        return .none
    }
}
```

---

## SettingsFlow 구현

### SettingsFlow.swift

```swift
import AsyncFlow
import UIKit
import SwiftUI

@MainActor
final class SettingsFlow: Flow {
    typealias StepType = SettingsStep
    
    var root: any Presentable { navigationController }
    private let navigationController = UINavigationController()
    private let services: AppServices
    
    init(services: AppServices) {
        self.services = services
    }
    
    func navigate(to step: SettingsStep) async -> FlowContributors<SettingsStep> {
        switch step {
        case .settings:
            return navigateToSettings()
            
        case .profile:
            return navigateToProfile()
            
        case .notifications:
            return navigateToNotifications()
            
        case .about:
            return navigateToAbout()
            
        case .logout:
            // AppFlow에서 처리하도록 위임
            return .none
            
        case .back:
            navigationController.popViewController(animated: true)
            return .none
        }
    }
    
    private func navigateToSettings() -> FlowContributors<SettingsStep> {
        let viewModel = SettingsViewModel()
        let viewController = SettingsViewController(viewModel: viewModel)
        
        navigationController.setViewControllers([viewController], animated: false)
        
        return .one(.contribute(presentable: viewController, stepper: viewModel))
    }
    
    private func navigateToProfile() -> FlowContributors<SettingsStep> {
        let viewModel = ProfileViewModel()
        let view = ProfileView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = "Profile"
        
        navigationController.pushViewController(viewController, animated: true)
        
        return .one(.contribute(presentable: viewController, stepper: viewModel))
    }
    
    private func navigateToNotifications() -> FlowContributors<SettingsStep> {
        let viewModel = NotificationsViewModel()
        let viewController = NotificationsViewController(viewModel: viewModel)
        
        navigationController.pushViewController(viewController, animated: true)
        
        return .one(.contribute(presentable: viewController, stepper: viewModel))
    }
    
    private func navigateToAbout() -> FlowContributors<SettingsStep> {
        let viewModel = AboutViewModel()
        let view = AboutView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = "About"
        
        navigationController.pushViewController(viewController, animated: true)
        
        return .one(.contribute(presentable: viewController, stepper: viewModel))
    }
}
```

---

## UIWindow Presentable 확장

### UIWindow+Presentable.swift

```swift
#if canImport(UIKit)
import UIKit
import AsyncFlow

extension UIWindow: Presentable {
    public var viewController: PlatformViewController {
        // UIWindow 자체를 래핑하는 투명한 ViewController
        if let root = rootViewController {
            return root
        }
        
        // rootViewController가 없으면 빈 ViewController 생성
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        return vc
    }
    
    public var isPresented: Bool {
        rootViewController != nil
    }
    
    public var onDismissed: AsyncStream<Void> {
        // UIWindow는 dismiss되지 않으므로 빈 스트림 반환
        AsyncStream { _ in }
    }
}
#endif
```

---

## 수정된 AppFlow

### AppFlow.swift

```swift
import AsyncFlow
import UIKit

@MainActor
final class AppFlow: Flow {
    typealias StepType = AppStep
    
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
    
    func navigate(to step: AppStep) async -> FlowContributors<AppStep> {
        switch step {
        case .launch:
            return navigateToLaunch()
            
        case .onboarding:
            return navigateToOnboarding()
            
        case .main:
            return navigateToMain()
            
        case .deepLink(let url):
            return navigateToDeepLink(url)
            
        case .loginRequired:
            return navigateToAuth()
            
        case .logout:
            return navigateToLogout()
            
        case let .dashboardRequired(dashboardStep):
            mainFlow?.navigate(to: .dashboardRequired(dashboardStep))
            return .none
            
        case let .settingsRequired(settingsStep):
            mainFlow?.navigate(to: .settingsRequired(settingsStep))
            return .none
            
        case let .authRequired(authStep):
            authFlow?.navigate(to: authStep)
            return .none
        }
    }
    
    private func navigateToLaunch() -> FlowContributors<AppStep> {
        // 로그인 상태 확인
        if services.authService.isLoggedIn {
            return .one(.contribute(
                presentable: self,
                stepper: OneStepper(.main)
            ))
        } else {
            return .one(.contribute(
                presentable: self,
                stepper: OneStepper(.loginRequired)
            ))
        }
    }
    
    private func navigateToOnboarding() -> FlowContributors<AppStep> {
        // 온보딩 화면 (생략)
        return .none
    }
    
    private func navigateToMain() -> FlowContributors<AppStep> {
        let mainFlow = MainFlow(services: services, coordinator: coordinator)
        self.mainFlow = mainFlow
        
        window.rootViewController = mainFlow.root.viewController
        window.makeKeyAndVisible()
        
        return .one(.contribute(
            presentable: mainFlow,
            stepper: OneStepper(.main)
        ))
    }
    
    private func navigateToAuth() -> FlowContributors<AppStep> {
        let authFlow = AuthFlow(services: services)
        self.authFlow = authFlow
        
        window.rootViewController = authFlow.root.viewController
        window.makeKeyAndVisible()
        
        return .one(.contribute(
            presentable: authFlow,
            stepper: OneStepper(AuthStep.login)
        ))
    }
    
    private func navigateToLogout() -> FlowContributors<AppStep> {
        services.authService.logout()
        authFlow = nil
        mainFlow = nil
        
        return .one(.contribute(
            presentable: self,
            stepper: OneStepper(.loginRequired)
        ))
    }
    
    private func navigateToDeepLink(_ url: URL) -> FlowContributors<AppStep> {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .none
        }
        
        switch components.path {
        case "/dashboard":
            return .one(.contribute(
                presentable: self,
                stepper: OneStepper(.main)
            ))
            
        case "/settings/profile":
            // Main으로 이동 후 Settings Profile 표시
            if mainFlow == nil {
                // Main Flow 먼저 생성
                _ = await navigate(to: .main)
            }
            
            return .one(.contribute(
                presentable: self,
                stepper: OneStepper(.settingsRequired(.profile))
            ))
            
        default:
            return .none
        }
    }
}
```

---

## 수정된 AppDelegate

### AppDelegate.swift

```swift
import UIKit
import AsyncFlow

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let coordinator = FlowCoordinator()
    
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
            coordinator: coordinator  // ← coordinator 전달
        )
        let appStepper = OneStepper(AppStep.launch)
        
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
        
        coordinator.coordinate(flow: appFlow, with: appStepper)
        
        return true
    }
    
    // Deep Link 처리
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // AppFlow에 Deep Link Step 전달
        // coordinator를 통해 처리하려면 별도의 Stepper 필요
        return true
    }
}
```

---

## 구현 우선순위

### Phase 1: 기본 구조 (필수)
1. Models (Feature, User, AppServices)
2. Steps (AppStep, DashboardStep, SettingsStep, AuthStep)
3. Services (Mock 구현)
4. UIWindow+Presentable

### Phase 2: Core Flows (필수)
1. AppFlow
2. MainFlow
3. DashboardFlow
4. SettingsFlow
5. AuthFlow

### Phase 3: ViewModels & Views (SwiftUI 우선)
1. DashboardHomeViewModel + DashboardHomeView
2. LoginViewModel + LoginView
3. ProfileViewModel + ProfileView
4. AboutViewModel + AboutView

### Phase 4: ViewModels & Views (UIKit)
1. SettingsViewModel + SettingsViewController
2. FeatureDetailViewModel + FeatureDetailViewController
3. NotificationsViewModel + NotificationsViewController
4. RegisterViewModel + RegisterViewController

### Phase 5: 고급 기능
1. Deep Link 처리
2. adapt() 권한 체크
3. Analytics 통합
4. 테스트 작성

---

**Created by 정준영 on 2025. 12. 29.**
**Revised on 2025. 12. 29.**

