import SwiftUI
import UIKit

struct ChessBoardView: View {
    @State private var boardSide: CGFloat = 0
    @GestureState private var draggedSquare: Square?

    let position: ChessPosition
    var selectedSquare: Square?
    var legalDestinations: Set<Square>
    var lastMove: ChessMove?
    var isInteractive: Bool
    var onTap: (Square) -> Void
    var onDrag: (Square, Square) -> Void

    init(
        position: ChessPosition,
        selectedSquare: Square? = nil,
        legalDestinations: Set<Square> = [],
        lastMove: ChessMove? = nil,
        isInteractive: Bool = true,
        onTap: @escaping (Square) -> Void = { _ in },
        onDrag: @escaping (Square, Square) -> Void = { _, _ in }
    ) {
        self.position = position
        self.selectedSquare = selectedSquare
        self.legalDestinations = legalDestinations
        self.lastMove = lastMove
        self.isInteractive = isInteractive
        self.onTap = onTap
        self.onDrag = onDrag
    }

    var body: some View {
        LazyVGrid(columns: Self.columns, spacing: 0) {
            ForEach(Self.displaySquares, id: \.self) { square in
                BoardSquareView(
                    square: square,
                    piece: position.piece(at: square),
                    isSelected: selectedSquare == square,
                    isLegalDestination: legalDestinations.contains(square),
                    isLastMoveSquare: lastMove?.from == square || lastMove?.to == square,
                    isBeingDragged: draggedSquare == square,
                    action: { onTap(square) }
                )
                .aspectRatio(1, contentMode: .fit)
                .disabled(!isInteractive)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 720)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.32), radius: 18, y: 10)
        .contentShape(Rectangle())
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            boardSide = newWidth
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .updating($draggedSquare) { value, state, _ in
                    guard isInteractive,
                          boardSide > 0,
                          let source = square(at: value.startLocation, boardSide: boardSide),
                          position.piece(at: source)?.color == .white else {
                        return
                    }
                    state = source
                }
                .onEnded { value in
                    guard isInteractive,
                          boardSide > 0,
                          let source = square(at: value.startLocation, boardSide: boardSide),
                          let destination = square(at: value.location, boardSide: boardSide) else {
                        return
                    }
                    onDrag(source, destination)
                }
        )
    }

    private func square(at point: CGPoint, boardSide: CGFloat) -> Square? {
        guard point.x >= 0, point.y >= 0, point.x < boardSide, point.y < boardSide else {
            return nil
        }

        let cellSize = boardSide / 8
        return Square(
            file: Int(point.x / cellSize),
            rank: 7 - Int(point.y / cellSize)
        )
    }

    private static let displaySquares = (0..<8).reversed().flatMap { rank in
        (0..<8).map { file in Square(file: file, rank: rank) }
    }

    private static let columns = Array(
        repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 0),
        count: 8
    )
}

private struct BoardSquareView: View {
    let square: Square
    let piece: ChessPiece?
    let isSelected: Bool
    let isLegalDestination: Bool
    let isLastMoveSquare: Bool
    let isBeingDragged: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                squareColor

                if isLastMoveSquare {
                    Color.yellow.opacity(0.22)
                }

                if isSelected {
                    AppTheme.accent.opacity(0.34)
                }

                if let piece {
                    ChessPieceView(piece: piece, isBeingDragged: isBeingDragged)
                        .transition(.scale.combined(with: .opacity))
                }

                if isLegalDestination {
                    if piece == nil {
                        Circle()
                            .fill(Color.black.opacity(0.34))
                            .frame(width: 13, height: 13)
                    } else {
                        Circle()
                            .stroke(AppTheme.accent.opacity(0.88), lineWidth: 4)
                            .padding(5)
                    }
                }

                coordinates
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityDescription)
        .animation(.easeInOut(duration: 0.18), value: piece?.square)
        .zIndex(isBeingDragged ? 1 : 0)
    }

    private var squareColor: Color {
        (square.file + square.rank).isMultiple(of: 2) ? AppTheme.darkSquare : AppTheme.lightSquare
    }

    @ViewBuilder
    private var coordinates: some View {
        if square.file == 0 || square.rank == 0 {
            VStack {
                HStack {
                    if square.file == 0 {
                        Text("\(square.rank + 1)")
                    }
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    if square.rank == 0 {
                        Text(Self.fileLabels[square.file])
                    }
                }
            }
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(Color.black.opacity(0.48))
            .padding(3)
            .allowsHitTesting(false)
        }
    }

    private var accessibilityDescription: String {
        let coordinate = square.algebraicNotation ?? "未知格"
        guard let piece else {
            return isLegalDestination ? "\(coordinate)，合法目的格" : coordinate
        }
        return "\(coordinate)，\(piece.accessibilityName)"
    }

    private static let fileLabels = ["a", "b", "c", "d", "e", "f", "g", "h"]
}

private struct ChessPieceView: View {
    let piece: ChessPiece
    let isBeingDragged: Bool

    var body: some View {
        Group {
            if let image = UIImage(named: piece.assetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(piece.color == .white ? .white : .black)
                    .accessibilityLabel("棋子素材載入失敗")
            }
        }
        .padding(5)
        .scaleEffect(isBeingDragged ? 1.08 : 1)
        .shadow(
            color: piece.color == .white ? .black.opacity(0.34) : .white.opacity(0.20),
            radius: isBeingDragged ? 5 : 2,
            y: isBeingDragged ? 3 : 1
        )
        .animation(.easeOut(duration: 0.16), value: isBeingDragged)
        .allowsHitTesting(false)
    }
}

private extension ChessPiece {
    var assetName: String {
        switch (color, kind) {
        case (.white, .king): "ChessWhiteKing"
        case (.white, .rook): "ChessWhiteRook"
        case (.black, .king): "ChessBlackKing"
        case (.white, .queen): "ChessWhiteQueen"
        case (.white, .pawn): "ChessWhitePawn"
        case (.black, .rook): "ChessBlackRook"
        case (.black, .queen): "ChessBlackQueen"
        case (.black, .pawn): "ChessBlackPawn"
        }
    }

    var accessibilityName: String {
        switch (color, kind) {
        case (.white, .king): "白王"
        case (.white, .rook): "白車"
        case (.black, .king): "黑王"
        case (.white, .queen): "白后"
        case (.white, .pawn): "白兵"
        case (.black, .rook): "黑車"
        case (.black, .queen): "黑后"
        case (.black, .pawn): "黑兵"
        }
    }
}
