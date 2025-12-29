//
//  MockStepper.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// 테스트용 Stepper
///
/// Step을 수동으로 방출하고 스트림을 제어할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// @Test
/// func testStepEmission() async {
///     let mockStepper = MockStepper<MovieStep>()
///     var receivedSteps: [MovieStep] = []
///
///     Task {
///         for await step in mockStepper.steps {
///             receivedSteps.append(step)
///         }
///     }
///
///     // Step 방출
///     mockStepper.emit(.movieList)
///     mockStepper.emit(.movieDetail(id: 1))
///
///     try await Task.sleep(for: .milliseconds(100))
///
///     #expect(receivedSteps == [.movieList, .movieDetail(id: 1)])
/// }
/// ```
@MainActor
public final class MockStepper<S: Step>: Stepper {
    public typealias StepType = S
    
    // MARK: - Properties
    
    /// 구독 시작 감지 콜백 (테스트 동기화용)
    public var onObservationStart: (() -> Void)?
    
    /// Step 스트림
    public var steps: AsyncStream<S> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
            
            // 구독자가 생겼음을 알림
            Task { @MainActor [weak self] in
                self?.onObservationStart?()
            }
            
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuation = nil
                }
            }
        }
    }
    
    private var continuation: AsyncStream<S>.Continuation?
    
    /// 방출된 Step 목록 (추적용)
    public private(set) var emittedSteps: [S] = []
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Step 방출
    ///
    /// - Parameter step: 방출할 Step
    public func emit(_ step: S) {
        emittedSteps.append(step)
        continuation?.yield(step)
    }
    
    /// 여러 Step 연속 방출
    ///
    /// - Parameter steps: 방출할 Step 배열
    public func emit(_ steps: [S]) {
        for step in steps {
            emit(step)
        }
    }
    
    /// Step 방출 후 대기
    ///
    /// - Parameters:
    ///   - step: 방출할 Step
    ///   - duration: 대기 시간 (초)
    public func emit(_ step: S, waitFor duration: TimeInterval) async {
        emit(step)
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
    
    /// 스트림 종료
    public func complete() {
        continuation?.finish()
        continuation = nil
    }
    
    /// 추적 데이터 초기화
    public func reset() {
        emittedSteps.removeAll()
    }
}
