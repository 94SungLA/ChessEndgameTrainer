import Foundation

nonisolated struct ChessRulesEngine: Sendable {
    private static let kingOffsets = [
        (-1, -1), (0, -1), (1, -1),
        (-1, 0),             (1, 0),
        (-1, 1),  (0, 1),   (1, 1)
    ]

    private static let rookDirections = [
        (-1, 0), (1, 0), (0, -1), (0, 1)
    ]

    func pseudoLegalMoves(for piece: ChessPiece, in position: ChessPosition) -> [ChessMove] {
        guard piece.color == position.sideToMove,
              position.piece(withID: piece.id) != nil else {
            return []
        }

        switch piece.kind {
        case .king:
            return kingMoves(for: piece, in: position)
        case .rook:
            return rookMoves(for: piece, in: position)
        case .queen, .pawn:
            return []
        }
    }

    func legalMoves(for piece: ChessPiece, in position: ChessPosition) -> [ChessMove] {
        pseudoLegalMoves(for: piece, in: position).filter { move in
            let nextPosition = applyingUnchecked(move, to: position)
            guard nextPosition.king(for: piece.color) != nil,
                  nextPosition.king(for: piece.color.opponent) != nil,
                  !kingsAreAdjacent(in: nextPosition) else {
                return false
            }
            return !isInCheck(piece.color, in: nextPosition)
        }
    }

    func legalMoves(in position: ChessPosition) -> [ChessMove] {
        position.pieces
            .filter { $0.color == position.sideToMove }
            .flatMap { legalMoves(for: $0, in: position) }
    }

    func applying(_ move: ChessMove, to position: ChessPosition) -> ChessPosition? {
        guard legalMoves(in: position).contains(move) else { return nil }
        return applyingUnchecked(move, to: position)
    }

    func isSquareAttacked(
        _ square: Square,
        by attackingColor: PieceColor,
        in position: ChessPosition
    ) -> Bool {
        for piece in position.pieces where piece.color == attackingColor {
            switch piece.kind {
            case .king:
                let fileDistance = abs(piece.square.file - square.file)
                let rankDistance = abs(piece.square.rank - square.rank)
                if max(fileDistance, rankDistance) == 1 {
                    return true
                }
            case .rook:
                if rookAttacks(square, from: piece.square, in: position) {
                    return true
                }
            case .queen, .pawn:
                break
            }
        }
        return false
    }

    func isInCheck(_ color: PieceColor, in position: ChessPosition) -> Bool {
        guard let king = position.king(for: color) else { return false }
        return isSquareAttacked(king.square, by: color.opponent, in: position)
    }

    func outcome(of position: ChessPosition) -> GameOutcome {
        guard position.whiteRook != nil else { return .rookCaptured }

        let moves = legalMoves(in: position)
        guard moves.isEmpty else { return .inProgress }

        if isInCheck(position.sideToMove, in: position) {
            return .checkmate(winner: position.sideToMove.opponent)
        }
        return .stalemate
    }

    func isValidKingRookKingPosition(_ position: ChessPosition) -> Bool {
        guard position.pieces.count == 3,
              position.pieces.allSatisfy({ $0.square.isValid }),
              Set(position.pieces.map(\.square)).count == 3,
              position.pieces.filter({ $0.color == .white && $0.kind == .king }).count == 1,
              position.pieces.filter({ $0.color == .white && $0.kind == .rook }).count == 1,
              position.pieces.filter({ $0.color == .black && $0.kind == .king }).count == 1,
              !kingsAreAdjacent(in: position),
              !isInCheck(position.sideToMove.opponent, in: position) else {
            return false
        }
        return true
    }

    private func kingMoves(for piece: ChessPiece, in position: ChessPosition) -> [ChessMove] {
        Self.kingOffsets.compactMap { fileOffset, rankOffset in
            let destination = piece.square.offset(file: fileOffset, rank: rankOffset)
            guard destination.isValid else { return nil }

            let target = position.piece(at: destination)
            guard target?.color != piece.color, target?.kind != .king else { return nil }
            return ChessMove(
                pieceID: piece.id,
                from: piece.square,
                to: destination,
                capturedPieceID: target?.id
            )
        }
    }

    private func rookMoves(for piece: ChessPiece, in position: ChessPosition) -> [ChessMove] {
        var moves: [ChessMove] = []

        for (fileOffset, rankOffset) in Self.rookDirections {
            var destination = piece.square.offset(file: fileOffset, rank: rankOffset)
            while destination.isValid {
                if let target = position.piece(at: destination) {
                    if target.color != piece.color && target.kind != .king {
                        moves.append(
                            ChessMove(
                                pieceID: piece.id,
                                from: piece.square,
                                to: destination,
                                capturedPieceID: target.id
                            )
                        )
                    }
                    break
                }

                moves.append(
                    ChessMove(
                        pieceID: piece.id,
                        from: piece.square,
                        to: destination,
                        capturedPieceID: nil
                    )
                )
                destination = destination.offset(file: fileOffset, rank: rankOffset)
            }
        }
        return moves
    }

    private func rookAttacks(
        _ target: Square,
        from rookSquare: Square,
        in position: ChessPosition
    ) -> Bool {
        guard target != rookSquare else { return false }

        let fileStep: Int
        let rankStep: Int

        if rookSquare.file == target.file {
            fileStep = 0
            rankStep = target.rank > rookSquare.rank ? 1 : -1
        } else if rookSquare.rank == target.rank {
            fileStep = target.file > rookSquare.file ? 1 : -1
            rankStep = 0
        } else {
            return false
        }

        var square = rookSquare.offset(file: fileStep, rank: rankStep)
        while square != target {
            if position.piece(at: square) != nil {
                return false
            }
            square = square.offset(file: fileStep, rank: rankStep)
        }
        return true
    }

    private func kingsAreAdjacent(in position: ChessPosition) -> Bool {
        guard let whiteKing = position.king(for: .white),
              let blackKing = position.king(for: .black) else {
            return false
        }
        return chebyshevDistance(whiteKing.square, blackKing.square) <= 1
    }

    private func chebyshevDistance(_ first: Square, _ second: Square) -> Int {
        max(abs(first.file - second.file), abs(first.rank - second.rank))
    }

    private func applyingUnchecked(
        _ move: ChessMove,
        to position: ChessPosition
    ) -> ChessPosition {
        var nextPosition = position
        nextPosition.pieces.removeAll { $0.id == move.capturedPieceID }

        if let index = nextPosition.pieces.firstIndex(where: { $0.id == move.pieceID }) {
            nextPosition.pieces[index].square = move.to
        }

        nextPosition.sideToMove = position.sideToMove.opponent
        nextPosition.halfmoveClock += 1
        return nextPosition
    }
}
