import SwiftUI

struct StatisticsView: View {
    let records: [TrainingRecord]

    var body: some View {
        let statistics = TrainingStatistics.calculate(from: records)
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    StatisticsHeader()
                    StatisticsOverview(statistics: statistics)
                    DifficultyBestSection(bestMoves: statistics.bestMovesByDifficulty)
                    DailyProgressCard(statistics: statistics)
                    RecentTrainingSection(records: Array(records.prefix(8)))
                }
                .frame(maxWidth: 720)
                .padding(20)
            }
        }
        .navigationTitle("訓練統計")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StatisticsHeader: View {
    var body: some View {
        HStack(spacing: 16) {
            Image("StatisticsArt")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
            VStack(alignment: .leading, spacing: 5) {
                Text("你的殘局進度")
                    .font(AppFont.title(.title2))
                    .foregroundStyle(AppTheme.primaryText)
                Text("每一次完成與失誤，都會留下可追蹤的紀錄。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }
}

private struct StatisticsOverview: View {
    let statistics: TrainingStatistics

    var body: some View {
        HStack(spacing: 12) {
            StatisticTile(value: "\(statistics.totalAttempts)", label: "總訓練", icon: "scope")
            StatisticTile(value: "\(statistics.successRate)%", label: "成功率", icon: "chart.line.uptrend.xyaxis")
            StatisticTile(value: "\(statistics.successes)", label: "成功局數", icon: "checkmark.seal.fill")
        }
    }
}

private struct StatisticTile: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(AppTheme.accent)
            Text(value).font(AppFont.number(.title2)).foregroundStyle(AppTheme.primaryText)
            Text(label).font(.caption).foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.smallRadius))
        .overlay { RoundedRectangle(cornerRadius: AppTheme.smallRadius).stroke(AppTheme.cardBorder) }
    }
}

private struct DifficultyBestSection: View {
    let bestMoves: [Difficulty: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("各難度最佳步數").font(AppFont.title(.title3)).foregroundStyle(AppTheme.primaryText)
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                HStack {
                    Text(difficulty.title).font(.headline).foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(bestMoves[difficulty].map { "\($0) 步" } ?? "尚無紀錄")
                        .font(bestMoves[difficulty] == nil ? .subheadline : AppFont.number(.headline))
                        .foregroundStyle(bestMoves[difficulty] == nil ? AppTheme.secondaryText : AppTheme.gold)
                }
                if difficulty != .hard { Divider().overlay(AppTheme.cardBorder) }
            }
        }
        .appCard()
    }
}

private struct DailyProgressCard: View {
    let statistics: TrainingStatistics

    var body: some View {
        HStack(spacing: 15) {
            Image("DailyChallengeArt").resizable().scaledToFit().frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("今日挑戰").font(.headline).foregroundStyle(AppTheme.primaryText)
                Text(statistics.dailyCompleted ? "已完成 · 最佳 \(statistics.dailyBestMoves ?? 0) 步" : "尚未完成")
                    .font(.subheadline)
                    .foregroundStyle(statistics.dailyCompleted ? AppTheme.accent : AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: statistics.dailyCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(statistics.dailyCompleted ? AppTheme.accent : AppTheme.secondaryText)
        }
        .appCard()
    }
}

private struct RecentTrainingSection: View {
    let records: [TrainingRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("最近訓練").font(AppFont.title(.title3)).foregroundStyle(AppTheme.primaryText)
            if records.isEmpty {
                Text("完成第一局後，訓練結果會出現在這裡。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            } else {
                ForEach(records) { record in
                    RecentTrainingRow(record: record)
                }
            }
        }
        .appCard()
    }
}

private struct RecentTrainingRow: View {
    let record: TrainingRecord

    var body: some View {
        HStack {
            Image(systemName: record.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(record.isSuccess ? AppTheme.accent : AppTheme.error)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.outcomeTitle).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.primaryText)
                Text(record.completedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption).foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(record.moveCount) 步").font(AppFont.number(.headline)).foregroundStyle(AppTheme.primaryText)
                Text(record.isDailyChallenge ? "每日" : record.difficulty.title)
                    .font(.caption).foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}
