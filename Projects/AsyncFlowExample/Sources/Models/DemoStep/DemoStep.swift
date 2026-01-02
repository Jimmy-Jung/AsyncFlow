//
//  DemoStep.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 1.
//

import AsyncFlow

/// 데모앱의 모든 네비게이션 Step 정의
enum DemoStep: Step, Equatable {
    // MARK: - Screens

    /// 화면 A (Root)
    case screenA

    /// 화면 B
    case screenB

    /// 화면 C
    case screenC

    /// 화면 D
    case screenD

    /// 화면 E
    case screenE

    // MARK: - Navigation Actions

    /// 1단계 뒤로 가기
    case goBack

    /// 2단계 뒤로 가기
    case goBack2

    /// 3단계 뒤로 가기
    case goBack3

    /// 루트 화면으로 이동
    case goToRoot

    /// 특정 화면으로 이동
    case goToSpecific(Screen)

    /// DeepLink로 특정 화면 이동
    case deepLink(Screen)

    // MARK: - Screen Enum

    /// 화면 식별자
    enum Screen: String, Equatable, CaseIterable {
        case a
        case b
        case c
        case d
        case e

        /// Step으로 변환
        var step: DemoStep {
            switch self {
            case .a: return .screenA
            case .b: return .screenB
            case .c: return .screenC
            case .d: return .screenD
            case .e: return .screenE
            }
        }
    }
}
