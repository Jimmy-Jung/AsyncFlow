//
//  Project.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import ProjectDescription

let project = Project(
    name: "AsyncFlow",
    targets: [
        // AsyncFlow 라이브러리
        .target(
            name: "AsyncFlow",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.jimmyjung.asyncflow",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: []
        ),

        // AsyncFlow Tests
        .target(
            name: "AsyncFlowTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.jimmyjung.asyncflow.tests",
            deploymentTargets: .iOS("15.0"),
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "AsyncFlow"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "AsyncFlow",
            shared: true,
            buildAction: .buildAction(targets: ["AsyncFlow"]),
            testAction: .targets(
                ["AsyncFlowTests"],
                configuration: .debug,
                options: .options(coverage: true, codeCoverageTargets: ["AsyncFlow"])
            )
        ),
    ]
)
