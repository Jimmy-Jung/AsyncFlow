//
//  FlowMetadata.swift
//  AsyncFlow
//
//  Created by jimmy on 2026. 1. 3.
//

import Foundation

/// Flow가 관리하는 화면의 메타데이터
///
/// 앱에서 커스텀 메타데이터 타입을 정의하여 확장 가능합니다.
///
/// ## 사용 예시
///
/// ```swift
/// // 기본 메타데이터
/// let metadata = DefaultFlowMetadata(
///     identifier: "Profile",
///     displayName: "프로필"
/// )
///
/// // 커스텀 메타데이터
/// struct AppFlowMetadata: FlowMetadata {
///     let identifier: String
///     let displayName: String
///     let icon: String
///     let color: UIColor
/// }
/// ```
public protocol FlowMetadata: Sendable, Equatable {
    /// 화면 고유 식별자
    var identifier: String { get }

    /// 화면 표시 이름
    var displayName: String { get }
}

// MARK: - Default Implementation

/// 기본 FlowMetadata 구현
///
/// AsyncFlow가 제공하는 기본 메타데이터 타입입니다.
public struct DefaultFlowMetadata: FlowMetadata {
    public let identifier: String
    public let displayName: String

    public init(
        identifier: String,
        displayName: String
    ) {
        self.identifier = identifier
        self.displayName = displayName
    }
}

// MARK: - Auto-generating Metadata

/// 타입 정보로부터 자동 생성되는 메타데이터
///
/// FlowStepper의 타입 이름을 분석하여 자동으로 메타데이터를 생성합니다.
///
/// ## 생성 규칙
///
/// - `A_1ViewModel` → identifier: "A_1ViewModel", displayName: "A-1"
/// - `ProfileSettingsViewModel` → identifier: "ProfileSettingsViewModel", displayName: "Profile Settings"
/// - `Screen5ViewModel` → identifier: "Screen5ViewModel", displayName: "Screen 5"
public struct AutoFlowMetadata: FlowMetadata {
    public let identifier: String
    public let displayName: String

    /// 타입 이름으로 메타데이터 자동 생성
    ///
    /// - Parameter type: 메타데이터를 생성할 타입
    public init(from type: Any.Type) {
        let typeName = String(describing: type)
        identifier = typeName
        displayName = Self.generateDisplayName(from: typeName)
    }

    /// 타입 이름에서 표시 이름 생성
    ///
    /// - Parameter typeName: 타입 이름
    /// - Returns: 사람이 읽기 쉬운 표시 이름
    private static func generateDisplayName(from typeName: String) -> String {
        var name = typeName.replacingOccurrences(of: "ViewModel", with: "")

        // "_" → "-" 변환
        if name.contains("_") {
            return name.replacingOccurrences(of: "_", with: "-")
        }

        // CamelCase → Space
        name = name.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )

        // 숫자 앞에 공백
        name = name.replacingOccurrences(
            of: "([A-Za-z])([0-9])",
            with: "$1 $2",
            options: .regularExpression
        )

        return name.isEmpty ? typeName : name
    }
}
