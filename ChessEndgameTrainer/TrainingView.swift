import SwiftUI
import SwiftData

struct TrainingFlowView: View {
    @State private var session: GameSession
    @State private var feedbackService = FeedbackService()
    @State private var didSaveResult = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @Environment(\.modelContext) private var modelContext
    let onReturnHome: () -> Void

    init(configuration: TrainingConfiguration, onReturnHome: @escaping () -> Void) {
        _session = State(initialValue: GameSession(configuration: configuration))
        self.onReturnHome = onReturnHome
    }

    var body: some View {
        Group {
            if session.outcome == .inProgress {
                TrainingView(session: session)
            } else {
                TrainingResultView(
                    outcome: session.outcome,
                    moveCount: session.playerMoveCount,
                    difficulty: session.configuration.difficulty,
                    onRetry: {
                        didSaveResult = false
                        session.restart()
                    },
                    onReturnHome: onReturnHome
                )
            }
        }
        .animation(.easeInOut(duration: 0.28), value: session.outcome)
        .onChange(of: session.feedbackEventSequence) {
            guard let event = session.lastFeedbackEvent else { return }
            feedbackService.perform(event, soundEnabled: soundEnabled)
            saveResultIfNeeded()
        }
        .onDisappear {
            session.cancelPendingResponse()
        }
    }

    private func saveResultIfNeeded() {
        guard session.outcome != .inProgress, !didSaveResult else { return }
        let isDaily = session.configuration.mode == .dailyChallenge
        modelContext.insert(
            TrainingRecord(
                difficulty: session.configuration.difficulty,
                outcome: session.outcome,
                moveCount: session.playerMoveCount,
                isDailyChallenge: isDaily,
                dailyChallengeID: isDaily ? TrainingConfiguration.dailyIdentifier() : nil
            )
        )
        try? modelContext.save()
        didSaveResult = true
    }
}

struct TrainingView: View {
    let session: GameSession

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    TrainingHeaderView(session: session)
                    TrainingBoardSection(session: session)
                    feedbackArea
                    instructionCard
                }
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(session.configuration.mode == .dailyChallenge ? "每日挑戰" : "王車王訓練")
        .navigationBarTitleDisplayMode(.inline)
    }

}

private struct TrainingBoardSection: View {
    let session: GameSession

    var body: some View {
        ZStack {
            ChessBoardView(
                position: session.position,
                selectedSquare: session.selectedSquare,
                legalDestinations: session.legalDestinations,
                lastMove: session.lastMove,
                isInteractive: session.phase == .playerTurn,
                onTap: session.handleTap,
                onDrag: session.handleDrag
            )

            if session.phase == .blackThinking {
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(AppTheme.accent)
                    Text("黑王思考中")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(AppTheme.primaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private extension TrainingView {
    @ViewBuilder
    private var feedbackArea: some View {
        if let feedback = session.feedback {
            Label(feedback.message, systemImage: feedback.iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(feedback == .illegalMove ? AppTheme.error : AppTheme.warning)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(13)
                .background(
                    (feedback == .illegalMove ? AppTheme.error : AppTheme.warning).opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var instructionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(AppTheme.warning)
            Text("點一下白王或白車查看合法走法，再點目的格；也可以直接拖曳棋子。先用車限制空間，再讓白王逐步靠近。")
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
    }

}

private struct TrainingHeaderView: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: statusIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusColor)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(AppFont.title(.headline))
                    .foregroundStyle(AppTheme.primaryText)
                Text(session.selectedPieceID == nil ? "白方行棋" : "選擇一個標示格")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(session.playerMoveCount) 步")
                    .font(AppFont.number(.headline))
                    .foregroundStyle(AppTheme.primaryText)
                Text(session.configuration.difficulty.title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private var statusTitle: String {
        switch session.phase {
        case .playerTurn: "輪到你走"
        case .blackThinking: "黑王思考中"
        case .finished: "訓練完成"
        }
    }

    private var statusIcon: String {
        session.phase == .playerTurn ? "hand.tap.fill" : "ellipsis"
    }

    private var statusColor: Color {
        session.phase == .playerTurn ? AppTheme.accent : AppTheme.warning
    }
}

private struct TrainingPreview: View {
    @State private var session = GameSession(
        configuration: TrainingConfiguration(
            difficulty: .medium,
            seed: 2_026_0926,
            mode: .practice
        )
    )

    var body: some View {
        NavigationStack {
            TrainingView(session: session)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("Training – iPhone Portrait") {
    TrainingPreview()
}

private extension GameSessionFeedback {
    var message: String {
        switch self {
        case .selectWhitePiece: "請先選擇白王或白車。"
        case .illegalMove: "這不是合法走法，請使用棋盤上標示的目的格。"
        case .blackIsMoving: "請等黑王完成移動。"
        }
    }

    var iconName: String {
        switch self {
        case .selectWhitePiece: "hand.point.up.left.fill"
        case .illegalMove: "xmark.octagon.fill"
        case .blackIsMoving: "hourglass"
        }
    }
}
