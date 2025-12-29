//
//  Project.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.app(
    name: "AsyncFlowExample",
    bundleId: "com.jimmyjung.asyncflow.example",
    dependencies: [
        // AsyncFlow (로컬 프로젝트)
        .project(target: "AsyncFlow", path: "../AsyncFlow"),

        // AsyncViewModel (외부 패키지)
        .external(name: "AsyncViewModel"),
    ],
    settings: .app()
)
