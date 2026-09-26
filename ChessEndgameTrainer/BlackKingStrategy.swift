import Foundation

nonisolated struct BlackKingStrategy: Sendable {
    private let rules = ChessRulesEngine()
    private let evaluator = PositionEvaluator()

    func chooseMove(
        in position: ChessPosition,
        difficulty: Difficulty,
        using generator: inout SeededGenerator
    ) -> ChessMove? {
        guard position.sideToMove == .black else { return nil }
        let moves = rules.legalMoves(in: position)
        guard !moves.isEmpty else { return nil }

        switch difficulty {
        case .easy:
            return moves.randomElement(using: &generator)
        case .medium:
            return bestScoredMove(in: position, moves: moves, using: &generator)
        case .hard:
            return bestLookaheadMove(in: position, moves: moves, using: &generator)
        }
    }

    private func bestScoredMove(
        in position: ChessPosition,
        moves: [ChessMove],
        using generator: inout SeededGenerator
    ) -> ChessMove? {
        let scoredMoves = moves.compactMap { move -> (ChessMove, Int)? in
            guard let nextPosition = rules.applying(move, to: position) else { return nil }
            return (move, evaluator.score(nextPosition))
        }
        guard let bestScore = scoredMoves.map(\.1).max() else { return nil }
        return scoredMoves
            .filter { $0.1 == bestScore }
            .map(\.0)
            .randomElement(using: &generator)
    }

    private func bestLookaheadMove(
        in position: ChessPosition,
        moves: [ChessMove],
        using generator: inout SeededGenerator
    ) -> ChessMove? {
        let scoredMoves = moves.compactMap { move -> (ChessMove, Int)? in
            guard let blackPosition = rules.applying(move, to: position) else { return nil }

            if rules.outcome(of: blackPosition) != .inProgress {
                return (move, evaluator.score(blackPosition))
            }

            let whiteReplies = rules.legalMoves(in: blackPosition)
            let replyScores = whiteReplies.compactMap { reply -> Int? in
                guard let replyPosition = rules.applying(reply, to: blackPosition) else {
                    return nil
                }
                return evaluator.score(replyPosition)
            }
            return (move, replyScores.min() ?? evaluator.score(blackPosition))
        }

        guard let bestScore = scoredMoves.map(\.1).max() else { return nil }
        return scoredMoves
            .filter { $0.1 == bestScore }
            .map(\.0)
            .randomElement(using: &generator)
    }
}
