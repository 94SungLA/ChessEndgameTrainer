import Foundation

nonisolated enum PieceColor: String, Codable, CaseIterable, Sendable {
    case white
    case black

    var opponent: PieceColor {
        self == .white ? .black : .white
    }
}

nonisolated enum PieceKind: String, Codable, Sendable {
    case king
    case rook
    case queen
    case pawn
}

nonisolated enum Difficulty: String, Codable, CaseIterable, Sendable {
    case easy
    case medium
    case hard
}

nonisolated enum GameOutcome: Equatable, Sendable {
    case inProgress
    case checkmate(winner: PieceColor)
    case stalemate
    case rookCaptured
}

nonisolated struct Square: Hashable, Codable, Sendable {
    let file: Int
    let rank: Int

    var isValid: Bool {
        (0..<8).contains(file) && (0..<8).contains(rank)
    }

    func offset(file fileOffset: Int, rank rankOffset: Int) -> Square {
        Square(file: file + fileOffset, rank: rank + rankOffset)
    }

    var algebraicNotation: String? {
        guard isValid, let fileScalar = UnicodeScalar(97 + file) else { return nil }
        return "\(Character(fileScalar))\(rank + 1)"
    }
}

nonisolated struct ChessPieceID: Hashable, Codable, RawRepresentable, Sendable {
    let rawValue: String

    static let whiteKing = ChessPieceID(rawValue: "white-king")
    static let whiteRook = ChessPieceID(rawValue: "white-rook")
    static let blackKing = ChessPieceID(rawValue: "black-king")
}

nonisolated struct ChessPiece: Identifiable, Hashable, Codable, Sendable {
    let id: ChessPieceID
    let color: PieceColor
    let kind: PieceKind
    var square: Square
}

nonisolated struct ChessMove: Hashable, Codable, Sendable {
    let pieceID: ChessPieceID
    let from: Square
    let to: Square
    let capturedPieceID: ChessPieceID?
}

nonisolated struct ChessPosition: Equatable, Codable, Sendable {
    var pieces: [ChessPiece]
    var sideToMove: PieceColor
    var halfmoveClock: Int

    init(
        pieces: [ChessPiece],
        sideToMove: PieceColor = .white,
        halfmoveClock: Int = 0
    ) {
        self.pieces = pieces
        self.sideToMove = sideToMove
        self.halfmoveClock = halfmoveClock
    }

    func piece(at square: Square) -> ChessPiece? {
        pieces.first { $0.square == square }
    }

    func piece(withID id: ChessPieceID) -> ChessPiece? {
        pieces.first { $0.id == id }
    }

    func king(for color: PieceColor) -> ChessPiece? {
        pieces.first { $0.color == color && $0.kind == .king }
    }

    var whiteRook: ChessPiece? {
        pieces.first { $0.color == .white && $0.kind == .rook }
    }

    static func kingRookKing(
        whiteKing: Square,
        whiteRook: Square,
        blackKing: Square,
        sideToMove: PieceColor = .white
    ) -> ChessPosition {
        ChessPosition(
            pieces: [
                ChessPiece(id: .whiteKing, color: .white, kind: .king, square: whiteKing),
                ChessPiece(id: .whiteRook, color: .white, kind: .rook, square: whiteRook),
                ChessPiece(id: .blackKing, color: .black, kind: .king, square: blackKing)
            ],
            sideToMove: sideToMove
        )
    }
}
