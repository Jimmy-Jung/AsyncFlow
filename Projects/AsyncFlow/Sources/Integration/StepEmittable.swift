//
//  StepEmittable.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// ViewModel이 Step을 방출할 수 있게 하는 프로토콜
///
/// AsyncViewModel과 AsyncFlow를 통합하여 사용할 때
/// ViewModel이 Stepper 역할을 할 수 있게 합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @AsyncViewModel
/// final class MovieListViewModel: StepEmittable {
///     typealias StepType = MovieStep
///
///     // AsyncViewModel 표준 구조
///     enum Action {
///         case selectMovie(id: Int)
///     }
///
///     func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
///         switch action {
///         case .selectMovie(let id):
///             // State 변경 없이 Step만 방출
///             emit(.movieDetail(id: id))
///             return []
///         }
///     }
/// }
/// ```
@MainActor
public protocol StepEmittable: Stepper, AnyObject {
    /// Step 방출
    ///
    /// - Parameter step: 방출할 Step
    func emit(_ step: StepType)
}

// MARK: - Default Implementation

public extension StepEmittable {
    /// Step 스트림
    ///
    /// AsyncStreamBridge를 사용하여 멀티캐스팅을 지원합니다.
    var steps: AsyncStream<StepType> {
        return stepBridge.stream
    }

    /// Step 방출
    func emit(_ step: StepType) {
        stepBridge.yield(step)
    }

    // MARK: - Internal

    /// Bridge 저장소
    private var stepBridge: AsyncStreamBridge<StepType> {
        let id = ObjectIdentifier(self)

        if let bridge = StepEmittableStorage.shared.getBridge(for: id) as? AsyncStreamBridge<StepType> {
            return bridge
        }

        let bridge = AsyncStreamBridge<StepType>()
        StepEmittableStorage.shared.setBridge(bridge, for: id, owner: self)
        return bridge
    }
}

// MARK: - Storage

@MainActor
private final class StepEmittableStorage {
    static let shared = StepEmittableStorage()

    private struct WeakBox {
        weak var owner: AnyObject?
        let bridge: Any
    }

    private var storage: [ObjectIdentifier: WeakBox] = [:]

    private init() {}

    func getBridge(for id: ObjectIdentifier) -> Any? {
        cleanupDeallocatedObjects()
        return storage[id]?.bridge
    }

    func setBridge(_ bridge: Any, for id: ObjectIdentifier, owner: AnyObject) {
        storage[id] = WeakBox(owner: owner, bridge: bridge)
    }

    private func cleanupDeallocatedObjects() {
        storage = storage.filter { $0.value.owner != nil }
    }
}
