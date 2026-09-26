import Foundation

enum AppRoute: Hashable {
    case endgameSelection
    case training(TrainingConfiguration)
    case tutorial
    case statistics
}

struct TrainingConfiguration: Hashable {
    enum Mode: Hashable {
        case practice
        case dailyChallenge
    }

    let difficulty: Difficulty
    let seed: UInt64
    let mode: Mode

    static func practice(difficulty: Difficulty) -> TrainingConfiguration {
        TrainingConfiguration(
            difficulty: difficulty,
            seed: UInt64.random(in: UInt64.min...UInt64.max),
            mode: .practice
        )
    }

    static func dailyChallenge(on date: Date = Date(), calendar: Calendar = .current) -> TrainingConfiguration {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = UInt64(components.year ?? 0)
        let month = UInt64(components.month ?? 0)
        let day = UInt64(components.day ?? 0)
        let seed = year * 10_000 + month * 100 + day

        return TrainingConfiguration(difficulty: .medium, seed: seed, mode: .dailyChallenge)
    }

    static func dailyIdentifier(on date: Date = Date(), calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

extension Difficulty {
    var title: String {
        switch self {
        case .easy:
            "Easy"
        case .medium:
            "Medium"
        case .hard:
            "Hard"
        }
    }

    var summary: String {
        switch self {
        case .easy:
            "黑王較常選擇隨機走法，適合熟悉基本操作。"
        case .medium:
            "黑王會尋找空間與吃車機會，適合穩定練習。"
        case .hard:
            "黑王會預判你的下一步，失誤更容易受到懲罰。"
        }
    }
}
