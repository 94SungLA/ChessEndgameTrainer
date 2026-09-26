import SwiftUI

struct EndgameSelectionView: View {
    let onSelectDifficulty: (Difficulty) -> Void

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    KingRookKingCard(onSelectDifficulty: onSelectDifficulty)
                    ComingSoonEndgameCard(
                        assetName: "ChessWhiteQueen",
                        title: "王后王",
                        subtitle: "用王后封鎖並完成將死"
                    )
                    ComingSoonEndgameCard(
                        assetName: "ChessWhitePawn",
                        title: "王兵王",
                        subtitle: "對王、關鍵格與升變競賽"
                    )
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("選擇殘局")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("選擇今天的訓練")
                .font(AppFont.title(.largeTitle))
                .foregroundStyle(AppTheme.primaryText)
            Text("先建立可靠的王車王基本功，再逐步解鎖更多殘局。")
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}

private struct KingRookKingCard: View {
    let onSelectDifficulty: (Difficulty) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AppTheme.accent.opacity(0.13))
                    HStack(spacing: -7) {
                        Image("ChessWhiteKing").resizable().scaledToFit()
                        Image("ChessWhiteRook").resizable().scaledToFit()
                    }
                    .padding(8)
                }
                .frame(width: 82, height: 74)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("王 + 車 vs 王")
                        .font(AppFont.title(.title3))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("可完整遊玩")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            Text("選擇黑王的防守強度")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)

            VStack(spacing: 10) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyButton(difficulty: difficulty) {
                        onSelectDifficulty(difficulty)
                    }
                }
            }
        }
        .appCard()
    }
}

private struct DifficultyButton: View {
    let difficulty: Difficulty
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: difficulty.iconName)
                    .frame(width: 28)
                    .foregroundStyle(difficulty.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(difficulty.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(difficulty.summary)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(14)
            .background(Color.black.opacity(0.17), in: RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }
}

private struct ComingSoonEndgameCard: View {
    let assetName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(width: 56, height: 56)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 15))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Text("COMING SOON")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(AppTheme.warning)
        }
        .appCard()
        .opacity(0.72)
    }
}

private extension Difficulty {
    var iconName: String {
        switch self {
        case .easy: "leaf.fill"
        case .medium: "shield.lefthalf.filled"
        case .hard: "flame.fill"
        }
    }

    var tint: Color {
        switch self {
        case .easy: AppTheme.accent
        case .medium: AppTheme.warning
        case .hard: AppTheme.error
        }
    }
}
