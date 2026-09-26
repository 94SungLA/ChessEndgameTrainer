import SwiftUI

struct HomeView: View {
    let onStartTraining: () -> Void
    let onDailyChallenge: () -> Void
    let onOpenTutorial: () -> Void
    let onOpenStatistics: () -> Void
    let records: [TrainingRecord]
    @AppStorage("soundEnabled") private var soundEnabled = true

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    Button(action: onStartTraining) {
                        Label("開始王車王訓練", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    dailyCard
                    Button(action: onOpenStatistics) {
                    HStack {
                        Image("StatisticsArt")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                        Text("訓練摘要")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Text("查看完整統計")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(AppTheme.accent)
                    }
                    }
                    .buttonStyle(.plain)
                    HStack(spacing: 12) {
                        HomeMetric(value: "\(statistics.totalAttempts)", label: "完成局數", icon: "scope")
                        HomeMetric(value: bestMovesText, label: "最佳步數", icon: "trophy.fill")
                        HomeMetric(value: "\(statistics.successRate)%", label: "成功率", icon: "chart.line.uptrend.xyaxis")
                    }
                    tutorialCard
                    Toggle(isOn: $soundEnabled) {
                        Label("音效", systemImage: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    .tint(AppTheme.accent)
                    .appCard()
                }
                .frame(maxWidth: 720)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var statistics: TrainingStatistics {
        TrainingStatistics.calculate(from: records)
    }

    private var bestMovesText: String {
        statistics.bestMovesByDifficulty.values.min().map(String.init) ?? "—"
    }

    private var hero: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                Image("HomeHero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                LinearGradient(colors: [.clear, AppTheme.background.opacity(0.96)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 7) {
                    Text("CHESS ENDGAME TRAINER")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(AppTheme.accent)
                    Text("把殘局練成直覺")
                    .font(AppFont.title(.largeTitle))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("從王車王開始，練習真正可操作的將死技巧。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(20)
            }
        }
        .frame(height: 268)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.largeRadius, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: AppTheme.largeRadius).stroke(AppTheme.cardBorder) }
        .accessibilityElement(children: .combine)
    }

    private var dailyCard: some View {
        Button(action: onDailyChallenge) {
            HStack(spacing: 16) {
                Image("DailyChallengeArt").resizable().scaledToFit().frame(width: 70, height: 70)
                VStack(alignment: .leading, spacing: 5) {
                    Text("每日挑戰").font(AppFont.title(.title3)).foregroundStyle(AppTheme.primaryText)
                    Text(statistics.dailyCompleted ? "今日已完成 · 最佳 \(statistics.dailyBestMoves ?? 0) 步" : "所有玩家共享今天的固定局面")
                        .font(.caption)
                        .foregroundStyle(statistics.dailyCompleted ? AppTheme.accent : AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(AppTheme.accent)
            }
            .appCard()
        }
        .buttonStyle(.plain)
    }

    private var tutorialCard: some View {
        Button(action: onOpenTutorial) {
            HStack(spacing: 14) {
                Image(systemName: "book.closed.fill")
                    .font(.title2).foregroundStyle(AppTheme.gold)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text("王車王速成教學").font(.headline).foregroundStyle(AppTheme.primaryText)
                    Text("四個觀念，建立可靠的將死框架").font(.caption).foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(AppTheme.secondaryText)
            }
            .appCard()
        }
        .buttonStyle(.plain)
    }
}

private struct HomeMetric: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(AppTheme.accent)
            Text(value).font(AppFont.number(.title3)).foregroundStyle(AppTheme.primaryText)
            Text(label).font(.caption2).foregroundStyle(AppTheme.secondaryText).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.smallRadius))
        .overlay { RoundedRectangle(cornerRadius: AppTheme.smallRadius).stroke(AppTheme.cardBorder) }
    }
}
