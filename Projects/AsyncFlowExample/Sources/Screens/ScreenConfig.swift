import UIKit

/// 화면별 설정 정보
struct ScreenConfig: Equatable {
    let screen: DemoStep.Screen
    let title: String
    let emoji: String
    let color: UIColor

    static let all: [DemoStep.Screen: ScreenConfig] = [
        .a: ScreenConfig(
            screen: .a,
            title: "Screen A",
            emoji: "🔴",
            color: .systemRed
        ),
        .b: ScreenConfig(
            screen: .b,
            title: "Screen B",
            emoji: "🟠",
            color: .systemOrange
        ),
        .c: ScreenConfig(
            screen: .c,
            title: "Screen C",
            emoji: "🟡",
            color: .systemYellow
        ),
        .d: ScreenConfig(
            screen: .d,
            title: "Screen D",
            emoji: "🟢",
            color: .systemGreen
        ),
        .e: ScreenConfig(
            screen: .e,
            title: "Screen E",
            emoji: "🔵",
            color: .systemBlue
        ),
    ]
}
