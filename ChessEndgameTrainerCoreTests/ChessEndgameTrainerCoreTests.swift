import Testing
import SwiftData
import UIKit
@testable import ChessEndgameTrainer

struct ChessRulesEngineTests {
    private let rules = ChessRulesEngine()

    @Test func kingHasEightMovesInOpenCenter() throws {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 3, rank: 3),
            whiteRook: Square(file: 0, rank: 0),
            blackKing: Square(file: 7, rank: 7)
        )
        let king = try #require(position.king(for: .white))
        #expect(rules.legalMoves(for: king, in: position).count == 8)
    }

    @Test func kingsCannotMoveAdjacentToEachOther() throws {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 2, rank: 2),
            whiteRook: Square(file: 0, rank: 0),
            blackKing: Square(file: 4, rank: 3)
        )
        let king = try #require(position.king(for: .white))
        let destinations = Set(rules.legalMoves(for: king, in: position).map(\.to))
        #expect(!destinations.contains(Square(file: 3, rank: 2)))
        #expect(!destinations.contains(Square(file: 3, rank: 3)))
        #expect(!destinations.contains(Square(file: 3, rank: 4)))
    }

    @Test func kingCannotMoveIntoRookAttack() throws {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 7, rank: 7),
            whiteRook: Square(file: 3, rank: 0),
            blackKing: Square(file: 2, rank: 2),
            sideToMove: .black
        )
        let king = try #require(position.king(for: .black))
        let destinations = Set(rules.legalMoves(for: king, in: position).map(\.to))
        #expect(!destinations.contains(Square(file: 3, rank: 1)))
        #expect(!destinations.contains(Square(file: 3, rank: 2)))
        #expect(!destinations.contains(Square(file: 3, rank: 3)))
    }

    @Test func rookMovesStraightAndStopsAtBlockers() throws {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 3, rank: 3),
            whiteRook: Square(file: 3, rank: 1),
            blackKing: Square(file: 3, rank: 7)
        )
        let rook = try #require(position.whiteRook)
        let destinations = Set(rules.legalMoves(for: rook, in: position).map(\.to))
        #expect(destinations.contains(Square(file: 3, rank: 2)))
        #expect(!destinations.contains(Square(file: 3, rank: 3)))
        #expect(!destinations.contains(Square(file: 4, rank: 2)))
        #expect(destinations.count == 9)
    }

    @Test func blackKingCanCaptureUnprotectedRook() throws {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 0, rank: 0),
            whiteRook: Square(file: 2, rank: 2),
            blackKing: Square(file: 2, rank: 3),
            sideToMove: .black
        )
        let king = try #require(position.king(for: .black))
        let capture = rules.legalMoves(for: king, in: position).first {
            $0.to == Square(file: 2, rank: 2)
        }
        let move = try #require(capture)
        let nextPosition = try #require(rules.applying(move, to: position))
        #expect(nextPosition.whiteRook == nil)
        #expect(rules.outcome(of: nextPosition) == .rookCaptured)
    }

    @Test func blackKingCannotCaptureProtectedRook() throws {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 1, rank: 1),
            whiteRook: Square(file: 2, rank: 2),
            blackKing: Square(file: 2, rank: 3),
            sideToMove: .black
        )
        let king = try #require(position.king(for: .black))
        #expect(!rules.legalMoves(for: king, in: position).contains {
            $0.to == Square(file: 2, rank: 2)
        })
    }

    @Test func rookCanGiveCheck() {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 7, rank: 0),
            whiteRook: Square(file: 0, rank: 0),
            blackKing: Square(file: 0, rank: 7),
            sideToMove: .black
        )
        #expect(rules.isInCheck(.black, in: position))
    }

    @Test func pieceDoesNotAttackItsOwnSquare() {
        let rookSquare = Square(file: 3, rank: 3)
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 0, rank: 0),
            whiteRook: rookSquare,
            blackKing: Square(file: 7, rank: 7)
        )
        #expect(!rules.isSquareAttacked(rookSquare, by: .white, in: position))
    }

    @Test func detectsCheckmate() {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 2, rank: 6),
            whiteRook: Square(file: 0, rank: 0),
            blackKing: Square(file: 0, rank: 7),
            sideToMove: .black
        )
        #expect(rules.outcome(of: position) == .checkmate(winner: .white))
    }

    @Test func detectsStalemate() {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 2, rank: 5),
            whiteRook: Square(file: 1, rank: 6),
            blackKing: Square(file: 0, rank: 7),
            sideToMove: .black
        )
        #expect(!rules.isInCheck(.black, in: position))
        #expect(rules.outcome(of: position) == .stalemate)
    }

    @Test func generatedLegalMovesNeverLeaveOwnKingAttacked() throws {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 3, rank: 3),
            whiteRook: Square(file: 6, rank: 1),
            blackKing: Square(file: 5, rank: 5)
        )
        for move in rules.legalMoves(in: position) {
            let nextPosition = try #require(rules.applying(move, to: position))
            #expect(!rules.isInCheck(.white, in: nextPosition))
        }
    }
}

@MainActor
struct TrainingPersistenceTests {
    @Test func recordsPersistAndFetchFromSwiftData() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TrainingRecord.self, configurations: configuration)
        let context = container.mainContext
        context.insert(makeRecord(difficulty: .hard, moves: 9, dailyID: "2026-09-26"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TrainingRecord>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.difficulty == .hard)
        #expect(fetched.first?.isSuccess == true)
        #expect(fetched.first?.dailyChallengeID == "2026-09-26")
    }

    @Test func statisticsDeriveTotalsBestMovesAndDailyState() {
        let records = [
            makeRecord(difficulty: .easy, moves: 12),
            makeRecord(difficulty: .easy, moves: 8),
            TrainingRecord(
                difficulty: .hard,
                outcome: .rookCaptured,
                moveCount: 4,
                isDailyChallenge: false,
                dailyChallengeID: nil
            ),
            makeRecord(difficulty: .medium, moves: 10, dailyID: "2026-09-26")
        ]

        let statistics = TrainingStatistics.calculate(from: records, todayID: "2026-09-26")
        #expect(statistics.totalAttempts == 4)
        #expect(statistics.successes == 3)
        #expect(statistics.successRate == 75)
        #expect(statistics.bestMovesByDifficulty[.easy] == 8)
        #expect(statistics.bestMovesByDifficulty[.hard] == nil)
        #expect(statistics.dailyCompleted)
        #expect(statistics.dailyBestMoves == 10)
    }

    @Test func disabledSoundDoesNotStartAudioPlayback() {
        let service = FeedbackService()
        service.perform(.move, soundEnabled: false)
        #expect(service.playedEventCount == 0)
    }

    @Test func dailyCompletionSurvivesAContainerRestart() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appending(path: "ChessTrainer-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: storeURL) }
        let schema = Schema([TrainingRecord.self])
        let configuration = ModelConfiguration("PersistenceTest", schema: schema, url: storeURL)

        do {
            let firstContainer = try ModelContainer(for: schema, configurations: configuration)
            firstContainer.mainContext.insert(makeRecord(difficulty: .medium, moves: 7, dailyID: "2026-09-26"))
            try firstContainer.mainContext.save()
        }

        let relaunchedContainer = try ModelContainer(for: schema, configurations: configuration)
        let fetched = try relaunchedContainer.mainContext.fetch(FetchDescriptor<TrainingRecord>())
        let statistics = TrainingStatistics.calculate(from: fetched, todayID: "2026-09-26")
        #expect(statistics.dailyCompleted)
        #expect(statistics.dailyBestMoves == 7)
    }

    @Test func customFontRegistersFromTheAppBundle() {
        AppFont.register()
        #expect(UIFont(name: "SpaceGrotesk-Light_Bold", size: 18) != nil)
    }

    private func makeRecord(difficulty: Difficulty, moves: Int, dailyID: String? = nil) -> TrainingRecord {
        TrainingRecord(
            difficulty: difficulty,
            outcome: .checkmate(winner: .white),
            moveCount: moves,
            isDailyChallenge: dailyID != nil,
            dailyChallengeID: dailyID
        )
    }
}

struct BlackKingStrategyTests {
    private let rules = ChessRulesEngine()
    private let strategy = BlackKingStrategy()

    @Test(arguments: Difficulty.allCases)
    func everyDifficultyReturnsALegalMove(difficulty: Difficulty) throws {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 6, rank: 1),
            whiteRook: Square(file: 0, rank: 0),
            blackKing: Square(file: 3, rank: 4),
            sideToMove: .black
        )
        var generator = SeededGenerator(seed: 42)
        let move = try #require(
            strategy.chooseMove(in: position, difficulty: difficulty, using: &generator)
        )
        #expect(rules.legalMoves(in: position).contains(move))
    }

    @Test func strategyDoesNotMoveForWhite() {
        let position = ChessPosition.kingRookKing(
            whiteKing: Square(file: 6, rank: 1),
            whiteRook: Square(file: 0, rank: 0),
            blackKing: Square(file: 3, rank: 4)
        )
        var generator = SeededGenerator(seed: 42)
        #expect(strategy.chooseMove(
            in: position,
            difficulty: .hard,
            using: &generator
        ) == nil)
    }
}

struct PositionGeneratorTests {
    private let rules = ChessRulesEngine()
    private let generator = PositionGenerator()

    @Test(arguments: Difficulty.allCases)
    func sameSeedProducesSamePosition(difficulty: Difficulty) {
        let first = generator.generate(seed: 2_026, difficulty: difficulty)
        let second = generator.generate(seed: 2_026, difficulty: difficulty)
        #expect(first == second)
    }

    @Test(arguments: Difficulty.allCases)
    func generatedPositionsAreLegalAndPlayable(difficulty: Difficulty) {
        for seed in 0..<100 {
            let position = generator.generate(seed: UInt64(seed), difficulty: difficulty)
            #expect(rules.isValidKingRookKingPosition(position))
            #expect(rules.outcome(of: position) == .inProgress)
            #expect(position.sideToMove == .white)
            #expect(!rules.legalMoves(in: position).isEmpty)
        }
    }
}

@MainActor
struct GameSessionTests {
    @Test func selectingWhitePiecePublishesLegalDestinations() {
        let session = makeSession(
            position: .kingRookKing(
                whiteKing: Square(file: 0, rank: 0),
                whiteRook: Square(file: 2, rank: 2),
                blackKing: Square(file: 7, rank: 7)
            )
        )

        session.handleTap(on: Square(file: 2, rank: 2))

        #expect(session.selectedPieceID == .whiteRook)
        #expect(!session.legalDestinations.isEmpty)
        #expect(session.legalDestinations.contains(Square(file: 2, rank: 6)))
    }

    @Test func illegalMoveKeepsPositionAndProvidesFeedback() {
        let initialPosition = ChessPosition.kingRookKing(
            whiteKing: Square(file: 0, rank: 0),
            whiteRook: Square(file: 2, rank: 2),
            blackKing: Square(file: 7, rank: 7)
        )
        let session = makeSession(position: initialPosition)

        session.handleTap(on: Square(file: 2, rank: 2))
        session.handleTap(on: Square(file: 3, rank: 3))

        #expect(session.position == initialPosition)
        #expect(session.playerMoveCount == 0)
        #expect(session.feedback == .illegalMove)
        #expect(session.phase == .playerTurn)
    }

    @Test func legalPlayerMoveLocksInputUntilBlackResponds() {
        let session = makeSession(
            position: .kingRookKing(
                whiteKing: Square(file: 0, rank: 0),
                whiteRook: Square(file: 0, rank: 2),
                blackKing: Square(file: 7, rank: 7)
            )
        )

        session.handleTap(on: Square(file: 0, rank: 0))
        session.handleTap(on: Square(file: 1, rank: 0))

        #expect(session.playerMoveCount == 1)
        #expect(session.phase == .blackThinking)
        #expect(session.position.sideToMove == .black)

        session.performBlackMove()

        #expect(session.phase == .playerTurn)
        #expect(session.position.sideToMove == .white)
        #expect(session.lastMove?.pieceID == .blackKing)
    }

    @Test func matingMoveFinishesSession() {
        let session = makeSession(
            position: .kingRookKing(
                whiteKing: Square(file: 2, rank: 6),
                whiteRook: Square(file: 1, rank: 0),
                blackKing: Square(file: 0, rank: 7)
            )
        )

        session.handleTap(on: Square(file: 1, rank: 0))
        session.handleTap(on: Square(file: 0, rank: 0))

        #expect(session.outcome == .checkmate(winner: .white))
        #expect(session.phase == .finished)
        #expect(session.playerMoveCount == 1)
    }

    @Test func stalematingMoveFinishesSessionAndRestartRestoresInitialState() {
        let initialPosition = ChessPosition.kingRookKing(
            whiteKing: Square(file: 2, rank: 5),
            whiteRook: Square(file: 1, rank: 5),
            blackKing: Square(file: 0, rank: 7)
        )
        let session = makeSession(position: initialPosition)

        session.handleTap(on: Square(file: 1, rank: 5))
        session.handleTap(on: Square(file: 1, rank: 6))

        #expect(session.outcome == .stalemate)
        #expect(session.phase == .finished)

        session.restart()

        #expect(session.position == initialPosition)
        #expect(session.outcome == .inProgress)
        #expect(session.phase == .playerTurn)
        #expect(session.playerMoveCount == 0)
    }

    private func makeSession(position: ChessPosition) -> GameSession {
        GameSession(
            configuration: TrainingConfiguration(difficulty: .easy, seed: 42, mode: .practice),
            initialPosition: position,
            responseDelay: .zero,
            automaticallyResponds: false
        )
    }
}
