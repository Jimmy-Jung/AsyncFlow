//
//  Flows.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

#if canImport(UIKit)
    import UIKit

    /// Flow 유틸리티 함수 모음
    ///
    /// RxFlow의 Flows 유틸리티와 동일한 기능을 제공합니다.
    public enum Flows {
        /// Flow 사용 전략
        public enum ExecuteStrategy {
            /// Flow가 ready될 때까지 대기
            case ready
            /// Flow 생성 즉시 실행
            case created
        }

        /// 단일 Flow 사용
        ///
        /// - Parameters:
        ///   - flow: 사용할 Flow
        ///   - strategy: 실행 전략
        ///   - block: Flow의 root를 받아 실행할 클로저
        ///
        /// ## 사용 예시
        ///
        /// ```swift
        /// let settingsFlow = SettingsFlow()
        ///
        /// Flows.use(settingsFlow, when: .ready) { [weak self] root in
        ///     self?.navigationController.present(root, animated: true)
        /// }
        /// ```
        @MainActor
        public static func use<Root: UIViewController>(
            _ flow: Flow,
            when strategy: ExecuteStrategy,
            block: @escaping @MainActor (_ flowRoot: Root) -> Void
        ) {
            guard let root = flow.root as? Root else {
                fatalError("Type mismatch: Flow root type does not match the expected type in the block")
            }

            switch strategy {
            case .created:
                block(root)
            case .ready:
                Task { @MainActor in
                    for await ready in flow.flowReady {
                        if ready {
                            block(root)
                            break
                        }
                    }
                }
            }
        }

        /// 복수 Flow 사용 (배열)
        ///
        /// - Parameters:
        ///   - flows: 사용할 Flow 배열
        ///   - strategy: 실행 전략
        ///   - block: Flow들의 root 배열을 받아 실행할 클로저
        @MainActor
        public static func use<Root: UIViewController>(
            _ flows: [Flow],
            when strategy: ExecuteStrategy,
            block: @escaping @MainActor ([Root]) -> Void
        ) {
            let roots = flows.compactMap { $0.root as? Root }
            guard roots.count == flows.count else {
                fatalError("Type mismatch: Flow roots types do not match the expected types in the block")
            }

            switch strategy {
            case .created:
                block(roots)
            case .ready:
                Task { @MainActor in
                    // 모든 Flow가 ready될 때까지 대기
                    for flow in flows {
                        for await ready in flow.flowReady {
                            if ready { break }
                        }
                    }
                    block(roots)
                }
            }
        }

        /// 2개 Flow 사용
        @MainActor
        public static func use<Root1: UIViewController, Root2: UIViewController>(
            _ flow1: Flow,
            _ flow2: Flow,
            when strategy: ExecuteStrategy,
            block: @escaping @MainActor (_ flow1Root: Root1, _ flow2Root: Root2) -> Void
        ) {
            guard let root1 = flow1.root as? Root1,
                  let root2 = flow2.root as? Root2
            else {
                fatalError("Type mismatch: Flow roots types do not match the expected types in the block")
            }

            switch strategy {
            case .created:
                block(root1, root2)
            case .ready:
                Task { @MainActor in
                    for await ready in flow1.flowReady {
                        if ready { break }
                    }
                    for await ready in flow2.flowReady {
                        if ready { break }
                    }
                    block(root1, root2)
                }
            }
        }

        /// 3개 Flow 사용
        @MainActor
        public static func use<Root1: UIViewController, Root2: UIViewController, Root3: UIViewController>(
            _ flow1: Flow,
            _ flow2: Flow,
            _ flow3: Flow,
            when strategy: ExecuteStrategy,
            block: @escaping @MainActor (_ flow1Root: Root1, _ flow2Root: Root2, _ flow3Root: Root3) -> Void
        ) {
            guard let root1 = flow1.root as? Root1,
                  let root2 = flow2.root as? Root2,
                  let root3 = flow3.root as? Root3
            else {
                fatalError("Type mismatch: Flow roots types do not match the expected types in the block")
            }

            switch strategy {
            case .created:
                block(root1, root2, root3)
            case .ready:
                Task { @MainActor in
                    for await ready in flow1.flowReady {
                        if ready { break }
                    }
                    for await ready in flow2.flowReady {
                        if ready { break }
                    }
                    for await ready in flow3.flowReady {
                        if ready { break }
                    }
                    block(root1, root2, root3)
                }
            }
        }

        /// 4개 Flow 사용
        @MainActor
        public static func use<
            Root1: UIViewController,
            Root2: UIViewController,
            Root3: UIViewController,
            Root4: UIViewController
        >(
            _ flow1: Flow,
            _ flow2: Flow,
            _ flow3: Flow,
            _ flow4: Flow,
            when strategy: ExecuteStrategy,
            block: @escaping @MainActor (_ flow1Root: Root1, _ flow2Root: Root2, _ flow3Root: Root3, _ flow4Root: Root4) -> Void
        ) {
            guard let root1 = flow1.root as? Root1,
                  let root2 = flow2.root as? Root2,
                  let root3 = flow3.root as? Root3,
                  let root4 = flow4.root as? Root4
            else {
                fatalError("Type mismatch: Flow roots types do not match the expected types in the block")
            }

            switch strategy {
            case .created:
                block(root1, root2, root3, root4)
            case .ready:
                Task { @MainActor in
                    for await ready in flow1.flowReady {
                        if ready { break }
                    }
                    for await ready in flow2.flowReady {
                        if ready { break }
                    }
                    for await ready in flow3.flowReady {
                        if ready { break }
                    }
                    for await ready in flow4.flowReady {
                        if ready { break }
                    }
                    block(root1, root2, root3, root4)
                }
            }
        }

        /// 5개 Flow 사용
        @MainActor
        public static func use<
            Root1: UIViewController,
            Root2: UIViewController,
            Root3: UIViewController,
            Root4: UIViewController,
            Root5: UIViewController
        >(
            _ flow1: Flow,
            _ flow2: Flow,
            _ flow3: Flow,
            _ flow4: Flow,
            _ flow5: Flow,
            when strategy: ExecuteStrategy,
            block: @escaping @MainActor (
                _ flow1Root: Root1,
                _ flow2Root: Root2,
                _ flow3Root: Root3,
                _ flow4Root: Root4,
                _ flow5Root: Root5
            ) -> Void
        ) {
            guard let root1 = flow1.root as? Root1,
                  let root2 = flow2.root as? Root2,
                  let root3 = flow3.root as? Root3,
                  let root4 = flow4.root as? Root4,
                  let root5 = flow5.root as? Root5
            else {
                fatalError("Type mismatch: Flow roots types do not match the expected types in the block")
            }

            switch strategy {
            case .created:
                block(root1, root2, root3, root4, root5)
            case .ready:
                Task { @MainActor in
                    for await ready in flow1.flowReady {
                        if ready { break }
                    }
                    for await ready in flow2.flowReady {
                        if ready { break }
                    }
                    for await ready in flow3.flowReady {
                        if ready { break }
                    }
                    for await ready in flow4.flowReady {
                        if ready { break }
                    }
                    for await ready in flow5.flowReady {
                        if ready { break }
                    }
                    block(root1, root2, root3, root4, root5)
                }
            }
        }
    }

#endif
