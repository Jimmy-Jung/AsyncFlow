//
//  ModalViewModel.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import Foundation

@MainActor
final class ModalViewModel: FlowStepper {
    @Steps var steps

    var initialStep: Step { NoneStep() }
}
