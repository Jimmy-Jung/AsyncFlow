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
        settings: Settings? = nil,
        includeTestPlan: Bool = true
    ) -> Project {
        let targets = makeTargets(
            name: name,
            bundleId: bundleId,
            deploymentTargets: deploymentTargets,
            dependencies: dependencies,
            settings: settings
        )

        let schemes = makeSchemes(
            name: name,
            includeTestPlan: includeTestPlan
        )

        return Project(
            name: name,
            targets: targets,
            schemes: schemes
        )
    }

    // MARK: - Private Helpers

    private static func makeTargets(
        name: String,
        bundleId: String,
        deploymentTargets: DeploymentTargets,
        dependencies: [TargetDependency],
        settings: Settings?
    ) -> [Target] {
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
            sources: ["Tests/UnitTests/**", "Tests/Helpers/**"],
            dependencies: [.target(name: name)]
        )

        let uiTestTarget = Target.target(
            name: "\(name)UITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "\(bundleId).uitests",
            deploymentTargets: deploymentTargets,
            sources: ["Tests/UITests/**"],
            dependencies: [.target(name: name)]
        )

        return [appTarget, testTarget, uiTestTarget]
    }

    private static func makeSchemes(
        name: String,
        includeTestPlan: Bool
    ) -> [Scheme] {
        let testAction: TestAction = includeTestPlan
            ? .testPlans([.relativeToManifest("\(name).xctestplan")])
            : .targets([
                .init(stringLiteral: "\(name)Tests"),
                .init(stringLiteral: "\(name)UITests"),
            ], configuration: .debug)

        return [
            Scheme.scheme(
                name: name,
                shared: true,
                buildAction: .buildAction(targets: [.init(stringLiteral: name)]),
                testAction: testAction,
                runAction: .runAction(configuration: .debug),
                archiveAction: .archiveAction(configuration: .release),
                profileAction: .profileAction(configuration: .release),
                analyzeAction: .analyzeAction(configuration: .debug)
            ),
        ]
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
