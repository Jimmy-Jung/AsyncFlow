//
//  FlowLogger.swift
//  AsyncFlow
//
//  Created by 정준영 on 2026. 1. 2.
//

import Foundation

#if canImport(OSLog)
    import OSLog
#endif

/// 네비게이션 로깅을 위한 프로토콜
///
/// 외부 로깅 시스템(OSLog, Firebase, Sentry 등)을 주입하여 사용할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// // 커스텀 로거 구현
/// final class FirebaseFlowLogger: FlowLogger {
///     func log(navigationStack: NavigationStack) {
///         Analytics.logEvent("navigation", parameters: [
///             "flow": navigationStack.flowName,
///             "depth": navigationStack.depth,
///             "steps": navigationStack.steps.map(\.description).joined(separator: " -> ")
///         ])
///     }
/// }
///
/// // FlowCoordinator에 주입
/// let coordinator = FlowCoordinator(logger: FirebaseFlowLogger())
/// ```
@MainActor
public protocol FlowLogger {
    /// 네비게이션 스택 로그 출력
    ///
    /// - Parameter navigationStack: 현재 네비게이션 스택 정보
    func log(navigationStack: NavigationStack)
}

// MARK: - NavigationStack

/// 네비게이션 스택 정보
public struct NavigationStack: Sendable {
    /// Flow 이름
    public let flowName: String

    /// Step 목록 (각 StepInfo에 metadata 포함)
    public let steps: [StepInfo]

    /// 스택 깊이
    public var depth: Int { steps.count }

    /// 메타데이터 목록 (StepInfo에서 추출, 하위 호환성용)
    public var metadata: [any FlowMetadata]? {
        let extracted = steps.compactMap { $0.metadata }
        return extracted.isEmpty ? nil : extracted
    }

    /// 생성자
    public init(flowName: String, steps: [StepInfo]) {
        self.flowName = flowName
        self.steps = steps
    }
}

// MARK: - StepInfo

/// Step 정보 (FlowMetadata 통합)
public struct StepInfo: Sendable {
    /// Step 타입 이름 (예: "MovieStep")
    public let typeName: String

    /// Step 케이스 설명 (예: "movieDetail(id: 1)")
    public let caseDescription: String

    /// FlowMetadata (NavigationFlow에서 Stepper로부터 추출)
    public let metadata: (any FlowMetadata)?

    /// 전체 설명 (typeName.caseDescription)
    public var description: String {
        "\(typeName).\(caseDescription)"
    }

    /// 표시 이름 (metadata가 있으면 metadata.displayName, 없으면 caseDescription)
    public var displayName: String {
        metadata?.displayName ?? caseDescription
    }

    /// 생성자
    public init(typeName: String, caseDescription: String, metadata: (any FlowMetadata)? = nil) {
        self.typeName = typeName
        self.caseDescription = caseDescription
        self.metadata = metadata
    }

    /// Step으로부터 생성
    public init(step: Step, metadata: (any FlowMetadata)? = nil) {
        let fullDescription = String(describing: step)
        let typeName = String(describing: type(of: step))

        // "DemoStep.screenA" → "screenA"
        // "DemoStep.goToSpecific(DemoStep.Screen.b)" → "goToSpecific(Screen.b)"
        if fullDescription.hasPrefix(typeName + ".") {
            // 타입 이름과 첫 번째 점을 제거
            let startIndex = fullDescription.index(fullDescription.startIndex, offsetBy: typeName.count + 1)
            let caseOnly = String(fullDescription[startIndex...])

            // associated value가 있는 경우, 내부의 타입 이름 제거
            // "goToSpecific(DemoStep.Screen.b)" → "goToSpecific(b)"
            let cleanedCase = caseOnly.replacingOccurrences(of: typeName + ".", with: "")

            self.typeName = typeName
            caseDescription = cleanedCase
            self.metadata = metadata
        } else {
            // 타입명이 포함되지 않은 경우 (드물지만)
            self.typeName = typeName
            caseDescription = fullDescription
            self.metadata = metadata
        }
    }
}

// MARK: - ConsoleFlowLogger

/// 콘솔에 로그를 출력하는 기본 구현
///
/// ## 출력 형식
///
/// ```
/// LoginFlow
/// loginStart -> emailInput -> passwordInput -> loginSuccess
/// Depth: 4
/// ```
@MainActor
public final class ConsoleFlowLogger: FlowLogger {
    /// 로그 출력 방식
    public enum OutputStyle {
        /// 단순 출력 (print)
        case simple
        /// 디버그 출력 (debugPrint)
        case debug
        /// OSLog 출력
        case osLog
    }

    private let style: OutputStyle

    /// 생성자
    ///
    /// - Parameter style: 로그 출력 방식 (기본값: .simple)
    public init(style: OutputStyle = .simple) {
        self.style = style
    }

    public func log(navigationStack: NavigationStack) {
        let message = formatNavigationStack(navigationStack)

        switch style {
        case .simple:
            print(message)
        case .debug:
            debugPrint(message)
        case .osLog:
            #if canImport(OSLog)
                if #available(iOS 14.0, macOS 11.0, *) {
                    let logger = Logger(subsystem: "com.asyncflow", category: "navigation")
                    logger.info("\(message)")
                } else {
                    print(message)
                }
            #else
                print(message)
            #endif
        }
    }

    /// 네비게이션 스택을 포맷팅
    private func formatNavigationStack(_ stack: NavigationStack) -> String {
        guard let currentStep = stack.steps.last else {
            return """
            ====== [\(stack.flowName)] ======
            📚 Stack: (empty)
            ======================
            """
        }

        // 현재 네비게이션할 Step (metadata가 있으면 displayName 사용)
        let currentStepDescription = currentStep.displayName

        // 전체 스택 경로 (metadata가 있으면 displayName, 없으면 caseDescription 사용)
        let stepPath = stack.steps.map { $0.displayName }.joined(separator: " → ")

        // Depth (스택 깊이)
        let depth = stack.depth

        return """
        ====== [\(stack.flowName)] ======
        🔄 Navigation willShow: \(currentStepDescription)
        📚 Stack updated: \(stepPath)
        📏 Depth: \(depth)
        ======================
        """
    }
}

// MARK: - NoOpFlowLogger

/// 로그를 출력하지 않는 Logger (기본값)
///
/// NoOpFlowLogger는 아무 작업도 수행하지 않으므로 메인 액터 격리가 필요하지 않습니다.
/// 이를 통해 FlowCoordinator의 기본 매개변수로 사용할 수 있습니다.
public struct NoOpFlowLogger: FlowLogger {
    public init() {}

    @MainActor
    public func log(navigationStack _: NavigationStack) {
        // 아무것도 하지 않음
    }
}
