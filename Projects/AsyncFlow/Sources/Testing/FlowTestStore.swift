//
//  FlowTestStore.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// Flow를 테스트하기 위한 스토어
///
/// Flow의 `navigate(to:)` 메서드를 호출하고
/// 처리된 Step과 반환된 FlowContributors를 추적합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @Test
/// func testMovieFlowNavigation() async {
///     let services = MockAppServices()
///     let flow = MovieFlow(services: services)
///     let store = FlowTestStore(flow: flow)
///
///     // Step 전달
///     let contributors = await store.navigate(to: .movieList)
///
///     // 검증
///     #expect(store.steps == [.movieList])
///
///     if case .one(.contribute(let presentable, let stepper)) = contributors {
///         #expect(presentable.viewController is MovieListViewController)
///         #expect(stepper is MovieListViewModel)
///     } else {
///         Issue.record("Expected one contributor")
///     }
/// }
/// ```
@MainActor
public final class FlowTestStore<F: Flow> {
    
    // MARK: - Properties
    
    /// 테스트 대상 Flow
    public let flow: F
    
    /// 처리된 Step 목록
    public private(set) var steps: [F.StepType] = []
    
    /// 반환된 FlowContributors 목록
    public private(set) var contributors: [FlowContributors<F.StepType>] = []
    
    // MARK: - Initialization
    
    /// FlowTestStore 초기화
    ///
    /// - Parameter flow: 테스트할 Flow
    public init(flow: F) {
        self.flow = flow
    }
    
    // MARK: - Public Methods
    
    /// Step을 Flow에 전달하고 결과 추적
    ///
    /// - Parameter step: 전달할 Step
    /// - Returns: Flow가 반환한 FlowContributors
    public func navigate(to step: F.StepType) async -> FlowContributors<F.StepType> {
        steps.append(step)
        
        let result = await flow.navigate(to: step)
        contributors.append(result)
        
        return result
    }
    
    /// 적응된 Step 확인
    ///
    /// - Parameter step: 확인할 Step
    /// - Returns: 적응된 Step (nil이면 필터링됨)
    public func adapt(step: F.StepType) async -> F.StepType? {
        return await flow.adapt(step: step)
    }
    
    /// 추적 데이터 초기화
    public func reset() {
        steps.removeAll()
        contributors.removeAll()
    }
}

