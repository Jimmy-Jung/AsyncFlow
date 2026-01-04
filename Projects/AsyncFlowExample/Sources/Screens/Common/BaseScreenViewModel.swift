//
//  BaseScreenViewModel.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import Foundation

/// 화면 ViewModel 베이스 클래스
@MainActor
class BaseScreenViewModel: FlowStepper {
    // MARK: - FlowStepper

    @Steps var steps

    var initialStep: Step { NoneStep() }

    // metadata는 FlowStepper extension에서 자동 제공됨
    // 커스텀이 필요한 경우에만 override

    // MARK: - Properties

    let depth: Int

    // MARK: - Initialization

    init(depth: Int) {
        self.depth = depth
    }
}
