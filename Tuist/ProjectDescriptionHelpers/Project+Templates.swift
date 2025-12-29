//
//  Project+Templates.swift
//  ProjectDescriptionHelpers
//
//  Created by 정준영 on 2025. 12. 29.
//

import ProjectDescription

// MARK: - Project Templates

public extension Project {
    /// 앱 프로젝트 템플릿
    static func app(
        name: String,
        bundleId: String,
        deploymentTargets: DeploymentTargets = .iOS("16.0"),
        dependencies: [TargetDependency] = [],
        settings: Settings? = nil
    ) -> Project {
        let appTarget = Target.target(
            name: name,
            destinations: .iOS,
            product: .app,
            bundleId: bundleId,
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "UILaunchStoryboardName": "LaunchScreen",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                ],
                "CFBundleDisplayName": "$(APP_DISPLAY_NAME)",
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: dependencies,
            settings: settings
        )

        let testTarget = Target.target(
            name: "\(name)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundleId).tests",
            deploymentTargets: deploymentTargets,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: name),
            ]
        )

        return Project(
            name: name,
            targets: [appTarget, testTarget]
        )
    }
}

// MARK: - Settings Templates

public extension Settings {
    static func app(
        configurations: [Configuration] = [
            .debug(name: "Debug", xcconfig: nil),
            .release(name: "Release", xcconfig: nil),
        ]
    ) -> Settings {
        return .settings(
            base: [
                "SWIFT_VERSION": "6.0",
                "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
                "TARGETED_DEVICE_FAMILY": "1", // iPhone only
                "SWIFT_STRICT_CONCURRENCY": "complete",
                "SWIFT_UPCOMING_FEATURE_CONCISE_MAGIC_FILE": "YES",
                "SWIFT_UPCOMING_FEATURE_EXIST_ANY_WHOLE_MODULE_EVALUATION": "YES",
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
            ],
            configurations: configurations
        )
    }
}
