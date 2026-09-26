import Foundation

nonisolated struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

nonisolated struct PositionGenerator: Sendable {
    private let rules = ChessRulesEngine()
    private let maximumAttempts = 10_000

    func generate(seed: UInt64, difficulty: Difficulty) -> ChessPosition {
        var generator = SeededGenerator(seed: seed)

        for _ in 0..<maximumAttempts {
            let squares = randomDistinctSquares(using: &generator)
            let position = ChessPosition.kingRookKing(
                whiteKing: squares[0],
                whiteRook: squares[1],
                blackKing: squares[2]
            )

            if isSuitable(position, for: difficulty) {
                return position
            }
        }
        return fallbackPosition(for: difficulty)
    }

    private func randomDistinctSquares(using generator: inout SeededGenerator) -> [Square] {
        var indices = Array(0..<64)
        indices.shuffle(using: &generator)
        return indices.prefix(3).map { index in
            Square(file: index % 8, rank: index / 8)
        }
    }

    private func isSuitable(_ position: ChessPosition, for difficulty: Difficulty) -> Bool {
        guard rules.isValidKingRookKingPosition(position),
              rules.outcome(of: position) == .inProgress,
              let whiteKing = position.king(for: .white),
              let blackKing = position.king(for: .black),
              let rook = position.whiteRook else {
            return false
        }

        let kingDistance = chebyshevDistance(whiteKing.square, blackKing.square)
        let rookDistance = chebyshevDistance(rook.square, blackKing.square)
        let rookIsProtected = rules.isSquareAttacked(
            rook.square,
            by: .white,
            in: position
        )
        guard rookDistance > 1 || rookIsProtected else { return false }

        let edgeDistance = min(
            blackKing.square.file,
            7 - blackKing.square.file,
            blackKing.square.rank,
            7 - blackKing.square.rank
        )

        switch difficulty {
        case .easy:
            return edgeDistance <= 1 && kingDistance <= 3
        case .medium:
            return kingDistance >= 2 && kingDistance <= 5
        case .hard:
            return edgeDistance >= 2 && kingDistance >= 4
        }
    }

    private func fallbackPosition(for difficulty: Difficulty) -> ChessPosition {
        switch difficulty {
        case .easy:
            return .kingRookKing(
                whiteKing: Square(file: 2, rank: 5),
                whiteRook: Square(file: 7, rank: 0),
                blackKing: Square(file: 0, rank: 7)
            )
        case .medium:
            return .kingRookKing(
                whiteKing: Square(file: 5, rank: 2),
                whiteRook: Square(file: 0, rank: 0),
                blackKing: Square(file: 3, rank: 5)
            )
        case .hard:
            return .kingRookKing(
                whiteKing: Square(file: 7, rank: 0),
                whiteRook: Square(file: 0, rank: 7),
                blackKing: Square(file: 3, rank: 3)
            )
        }
    }

    private func chebyshevDistance(_ first: Square, _ second: Square) -> Int {
        max(abs(first.file - second.file), abs(first.rank - second.rank))
    }
}
