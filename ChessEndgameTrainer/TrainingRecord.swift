import Foundation
import SwiftData

@Model
final class TrainingRecord {
    var completedAt: Date
    var difficultyRawValue: String
    var outcomeRawValue: String
    var moveCount: Int
    var isDailyChallenge: Bool
    var dailyChallengeID: String?

    init(
        completedAt: Date = .now,
        difficulty: Difficulty,
        outcome: GameOutcome,
        moveCount: Int,
        isDailyChallenge: Bool,
        dailyChallengeID: String?
    ) {
        self.completedAt = completedAt
        self.difficultyRawValue = difficulty.rawValue
        self.outcomeRawValue = outcome.storageValue
        self.moveCount = moveCount
        self.isDailyChallenge = isDailyChallenge
        self.dailyChallengeID = dailyChallengeID
    }

    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRawValue) ?? .medium
    }

    var isSuccess: Bool {
        outcomeRawValue == GameOutcome.checkmate(winner: .white).storageValue
    }

    var outcomeTitle: String {
        switch outcomeRawValue {
        case "checkmate-white": "將死成功"
        case "stalemate": "逼和"
        case "rook-captured": "白車被吃"
        default: "挑戰失敗"
        }
    }
}

struct TrainingStatistics: Equatable {
    let totalAttempts: Int
    let successes: Int
    let bestMovesByDifficulty: [Difficulty: Int]
    let dailyCompleted: Bool
    let dailyBestMoves: Int?

    var successRate: Int {
        guard totalAttempts > 0 else { return 0 }
        return Int((Double(successes) / Double(totalAttempts) * 100).rounded())
    }

    static func calculate(
        from records: [TrainingRecord],
        todayID: String = TrainingConfiguration.dailyIdentifier()
    ) -> TrainingStatistics {
        let successes = records.filter(\.isSuccess)
        var best: [Difficulty: Int] = [:]
        for difficulty in Difficulty.allCases {
            best[difficulty] = successes
                .filter { $0.difficulty == difficulty && !$0.isDailyChallenge }
                .map(\.moveCount)
                .min()
        }
        let dailySuccesses = successes.filter { $0.dailyChallengeID == todayID }
        return TrainingStatistics(
            totalAttempts: records.count,
            successes: successes.count,
            bestMovesByDifficulty: best,
            dailyCompleted: !dailySuccesses.isEmpty,
            dailyBestMoves: dailySuccesses.map(\.moveCount).min()
        )
    }
}

extension GameOutcome {
    var storageValue: String {
        switch self {
        case .inProgress: "in-progress"
        case .checkmate(winner: .white): "checkmate-white"
        case .checkmate(winner: .black): "checkmate-black"
        case .stalemate: "stalemate"
        case .rookCaptured: "rook-captured"
        }
    }
}
