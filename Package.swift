// swift-tools-version: 6.0
//
//  Package.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import PackageDescription

let package = Package(
    name: "AsyncFlow",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "AsyncFlow",
            targets: ["AsyncFlow"]
        ),
    ],
    targets: [
        // AsyncFlow 라이브러리
        .target(
            name: "AsyncFlow",
            dependencies: [],
            path: "Projects/AsyncFlow/Sources"
        ),

        // AsyncFlow Tests
        .testTarget(
            name: "AsyncFlowTests",
            dependencies: ["AsyncFlow"],
            path: "Projects/AsyncFlow/Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
