import SwiftUI

/// 네비게이션 스택에 표시되는 개별 화면 카드
struct ScreenCardView: View {
    let config: ScreenConfig
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Emoji Icon
            Text(config.emoji)
                .font(.system(size: 32))

            // Screen Name
            Text(config.screen.rawValue.uppercased())
                .font(.caption)
                .fontWeight(isActive ? .bold : .regular)
        }
        .frame(width: 60, height: 70)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(config.color).opacity(isActive ? 0.8 : 0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color(config.color) : Color.clear, lineWidth: 3)
        )
        .shadow(color: isActive ? Color(config.color).opacity(0.5) : Color.clear, radius: 8, x: 0, y: 4)
        .scaleEffect(isActive ? 1.1 : 0.9)
        .opacity(isActive ? 1.0 : 0.6)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}

#Preview {
    HStack(spacing: 20) {
        ScreenCardView(config: ScreenConfig.all[.a]!, isActive: false)
        ScreenCardView(config: ScreenConfig.all[.b]!, isActive: true)
        ScreenCardView(config: ScreenConfig.all[.c]!, isActive: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
