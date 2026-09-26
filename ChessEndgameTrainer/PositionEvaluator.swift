import Foundation

nonisolated struct PositionEvaluator: Sendable {
    private let rules = ChessRulesEngine()

    /// Returns a score from Black's perspective. Higher values favor the defending king.
    func score(_ position: ChessPosition) -> Int {
        switch rules.outcome(of: position) {
        case .rookCaptured:
            return 10_000
        case .stalemate:
            return 9_000
        case .checkmate(let winner):
            return winner == .black ? 10_000 : -10_000
        case .inProgress:
            break
        }

        guard let blackKing = position.king(for: .black),
              let whiteKing = position.king(for: .white),
              let whiteRook = position.whiteRook else {
            return 0
        }

        var blackTurnPosition = position
        blackTurnPosition.sideToMove = .black
        let mobility = rules.legalMoves(in: blackTurnPosition).count
        let centerDistance = distanceFromCenter(blackKing.square)
        let kingDistance = chebyshevDistance(blackKing.square, whiteKing.square)
        let rookDistance = chebyshevDistance(blackKing.square, whiteRook.square)

        var value = mobility * 24
        value -= centerDistance * 5
        value += kingDistance * 4
        value += max(0, 4 - rookDistance) * 8

        if rules.isInCheck(.black, in: position) {
            value -= 80
        }
        if rookDistance == 1 && !rules.isSquareAttacked(
            whiteRook.square,
            by: .white,
            in: position
        ) {
            value += 200
        }
        return value
    }

    private func distanceFromCenter(_ square: Square) -> Int {
        let centralFiles = [3, 4]
        let centralRanks = [3, 4]
        let fileDistance = centralFiles.map { abs(square.file - $0) }.min() ?? 0
        let rankDistance = centralRanks.map { abs(square.rank - $0) }.min() ?? 0
        return fileDistance + rankDistance
    }

    private func chebyshevDistance(_ first: Square, _ second: Square) -> Int {
        max(abs(first.file - second.file), abs(first.rank - second.rank))
    }
}
