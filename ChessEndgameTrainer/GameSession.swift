import Foundation
import Observation

enum GameSessionPhase: Equatable {
    case playerTurn
    case blackThinking
    case finished
}

enum GameSessionFeedback: Equatable {
    case selectWhitePiece
    case illegalMove
    case blackIsMoving
}

@MainActor
@Observable
final class GameSession {
    let configuration: TrainingConfiguration

    private(set) var position: ChessPosition
    private(set) var selectedPieceID: ChessPieceID?
    private(set) var legalDestinations: Set<Square> = []
    private(set) var playerMoveCount = 0
    private(set) var phase: GameSessionPhase
    private(set) var outcome: GameOutcome
    private(set) var feedback: GameSessionFeedback?
    private(set) var lastMove: ChessMove?
    private(set) var lastFeedbackEvent: TrainingFeedbackEvent?
    private(set) var feedbackEventSequence = 0

    private let initialPosition: ChessPosition
    private let rulesEngine: ChessRulesEngine
    private let blackStrategy: BlackKingStrategy
    private let responseDelay: Duration
    private let automaticallyResponds: Bool
    private var randomGenerator: SeededGenerator

    @ObservationIgnored
    private var blackResponseTask: Task<Void, Never>?

    init(
        configuration: TrainingConfiguration,
        initialPosition: ChessPosition? = nil,
        rulesEngine: ChessRulesEngine = ChessRulesEngine(),
        blackStrategy: BlackKingStrategy = BlackKingStrategy(),
        positionGenerator: PositionGenerator = PositionGenerator(),
        responseDelay: Duration = .milliseconds(380),
        automaticallyResponds: Bool = true
    ) {
        self.configuration = configuration
        self.rulesEngine = rulesEngine
        self.blackStrategy = blackStrategy
        self.responseDelay = responseDelay
        self.automaticallyResponds = automaticallyResponds

        let generatedPosition = initialPosition ?? positionGenerator.generate(
            seed: configuration.seed,
            difficulty: configuration.difficulty
        )
        self.initialPosition = generatedPosition
        self.position = generatedPosition
        self.randomGenerator = SeededGenerator(seed: configuration.seed ^ 0xA11C_E5E5_DA7A_BA5E)

        let initialOutcome = rulesEngine.outcome(of: generatedPosition)
        self.outcome = initialOutcome
        if initialOutcome != .inProgress {
            self.phase = .finished
        } else if generatedPosition.sideToMove == .white {
            self.phase = .playerTurn
        } else {
            self.phase = .blackThinking
        }
    }

    var selectedSquare: Square? {
        guard let selectedPieceID else { return nil }
        return position.piece(withID: selectedPieceID)?.square
    }

    func handleTap(on square: Square) {
        guard phase == .playerTurn else {
            feedback = .blackIsMoving
            publish(.invalid)
            return
        }

        if let piece = position.piece(at: square), piece.color == .white {
            select(piece: piece)
            return
        }

        guard selectedPieceID != nil else {
            feedback = .selectWhitePiece
            publish(.invalid)
            return
        }

        _ = attemptMove(to: square)
    }

    func handleDrag(from source: Square, to destination: Square) {
        guard phase == .playerTurn,
              let piece = position.piece(at: source),
              piece.color == .white else {
            feedback = phase == .blackThinking ? .blackIsMoving : .selectWhitePiece
            publish(.invalid)
            return
        }

        select(piece: piece)
        _ = attemptMove(to: destination)
    }

    @discardableResult
    func attemptMove(to destination: Square) -> Bool {
        guard phase == .playerTurn,
              let selectedPieceID,
              let selectedPiece = position.piece(withID: selectedPieceID),
              let move = rulesEngine.legalMoves(for: selectedPiece, in: position)
                .first(where: { $0.to == destination }),
              let updatedPosition = rulesEngine.applying(move, to: position) else {
            feedback = .illegalMove
            publish(.invalid)
            return false
        }

        position = updatedPosition
        playerMoveCount += 1
        lastMove = move
        clearSelection()
        feedback = nil

        guard !finishIfNeeded() else { return true }

        publish(rulesEngine.isInCheck(.black, in: position) ? .check : .move)

        phase = .blackThinking
        if automaticallyResponds {
            scheduleBlackResponse()
        }
        return true
    }

    func restart() {
        blackResponseTask?.cancel()
        position = initialPosition
        selectedPieceID = nil
        legalDestinations = []
        playerMoveCount = 0
        outcome = rulesEngine.outcome(of: initialPosition)
        phase = outcome == .inProgress ? .playerTurn : .finished
        feedback = nil
        lastMove = nil
        lastFeedbackEvent = nil
        randomGenerator = SeededGenerator(seed: configuration.seed ^ 0xA11C_E5E5_DA7A_BA5E)
    }

    func cancelPendingResponse() {
        blackResponseTask?.cancel()
        blackResponseTask = nil
    }

    // Internal so the session's turn transition can be tested without waiting for UI timing.
    func performBlackMove() {
        guard phase == .blackThinking, position.sideToMove == .black else { return }

        guard let move = blackStrategy.chooseMove(
            in: position,
            difficulty: configuration.difficulty,
            using: &randomGenerator
        ), let updatedPosition = rulesEngine.applying(move, to: position) else {
            _ = finishIfNeeded()
            return
        }

        position = updatedPosition
        lastMove = move
        feedback = nil

        if !finishIfNeeded() {
            publish(.move)
            phase = .playerTurn
        }
    }

    private func select(piece: ChessPiece) {
        selectedPieceID = piece.id
        legalDestinations = Set(rulesEngine.legalMoves(for: piece, in: position).map(\.to))
        feedback = nil
    }

    private func clearSelection() {
        selectedPieceID = nil
        legalDestinations = []
    }

    @discardableResult
    private func finishIfNeeded() -> Bool {
        outcome = rulesEngine.outcome(of: position)
        guard outcome != .inProgress else { return false }

        phase = .finished
        clearSelection()
        blackResponseTask?.cancel()
        publish(outcome == .checkmate(winner: .white) ? .success : .failure)
        return true
    }

    private func publish(_ event: TrainingFeedbackEvent) {
        lastFeedbackEvent = event
        feedbackEventSequence += 1
    }

    private func scheduleBlackResponse() {
        blackResponseTask?.cancel()
        let delay = responseDelay
        blackResponseTask = Task { @MainActor [weak self] in
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }
            guard !Task.isCancelled else { return }
            self?.performBlackMove()
        }
    }
}
