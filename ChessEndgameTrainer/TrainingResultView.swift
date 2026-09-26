import SwiftUI

struct TrainingResultView: View {
    let outcome: GameOutcome
    let moveCount: Int
    let difficulty: Difficulty
    let onRetry: () -> Void
    let onReturnHome: () -> Void

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    resultHero
                    resultMetrics
                    teachingFeedback
                    actions
                }
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden()
    }

    private var resultHero: some View {
        VStack(spacing: 14) {
            Image(resultAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 132)

            Text(resultTitle)
                .font(AppFont.title(.largeTitle))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
            Text(resultSubtitle)
                .font(.body)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var resultMetrics: some View {
        HStack(spacing: 12) {
            ResultMetric(value: "\(moveCount)", label: "玩家步數", icon: "arrow.right")
            ResultMetric(value: difficulty.title, label: "難度", icon: "speedometer")
        }
    }

    private var teachingFeedback: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("本局重點", systemImage: "graduationcap.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
            Text(feedbackText)
                .font(.body)
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button(action: onRetry) {
                Label("重新挑戰", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(PrimaryActionButtonStyle())

            Button(action: onReturnHome) {
                Label("回到首頁", systemImage: "house.fill")
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
    }

    private var resultTitle: String {
        switch outcome {
        case .checkmate(winner: .white): "將死成功"
        case .checkmate: "被將死"
        case .stalemate: "形成逼和"
        case .rookCaptured: "白車被吃"
        case .inProgress: "訓練進行中"
        }
    }

    private var resultSubtitle: String {
        switch outcome {
        case .checkmate(winner: .white): "你成功用白王與白車封住黑王。"
        case .checkmate: "重新整理局面，再試一次。"
        case .stalemate: "黑王沒有合法走法，但當下並未被將軍。"
        case .rookCaptured: "少了白車後，這個殘局已無法完成將死。"
        case .inProgress: "繼續完成這個局面。"
        }
    }

    private var feedbackText: String {
        switch outcome {
        case .checkmate(winner: .white):
            "做得好。最後一排的將死必須由白王控制黑王的逃生格，再由白車沿著邊線將軍。"
        case .checkmate:
            "讓白王留在安全格，並確認每次行棋後都不會走進黑王的控制範圍。"
        case .stalemate:
            "縮小空間時要保留黑王至少一個合法格，直到你準備好用車將軍；沒有將軍的無路可走就是逼和。"
        case .rookCaptured:
            "車與黑王至少保持一格安全距離，或確保白王正在保護車。移動前先檢查黑王下一步能否直接吃車。"
        case .inProgress:
            "先用車切割，再讓白王靠近支援。"
        }
    }

    private var resultIcon: String {
        switch outcome {
        case .checkmate(winner: .white): "crown.fill"
        case .checkmate: "xmark.shield.fill"
        case .stalemate: "equal.circle.fill"
        case .rookCaptured: "exclamationmark.triangle.fill"
        case .inProgress: "hourglass"
        }
    }

    private var resultAssetName: String {
        outcome == .checkmate(winner: .white) ? "ResultSuccessArt" : "ResultRetryArt"
    }

    private var resultColor: Color {
        switch outcome {
        case .checkmate(winner: .white): AppTheme.accent
        case .stalemate: AppTheme.warning
        case .rookCaptured, .checkmate: AppTheme.error
        case .inProgress: AppTheme.secondaryText
        }
    }
}

private struct ResultMetric: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
            Text(value)
                .font(AppFont.number(.title2))
                .foregroundStyle(AppTheme.primaryText)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .appCard()
    }
}
