import AVFAudio
import Foundation
import Observation
import UIKit

enum TrainingFeedbackEvent: Equatable {
    case move
    case check
    case invalid
    case success
    case failure
}

@MainActor
@Observable
final class FeedbackService {
    private(set) var playedEventCount = 0

    @ObservationIgnored
    private var audioPlayer: AVAudioPlayer?

    func perform(_ event: TrainingFeedbackEvent, soundEnabled: Bool) {
        performHaptic(for: event)
        guard soundEnabled, let url = Bundle.main.url(forResource: soundName(for: event), withExtension: "wav") else {
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            playedEventCount += 1
        } catch {
            audioPlayer = nil
        }
    }

    private func performHaptic(for event: TrainingFeedbackEvent) {
        switch event {
        case .move:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .check:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .invalid, .failure:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func soundName(for event: TrainingFeedbackEvent) -> String {
        switch event {
        case .move: "move"
        case .check: "check"
        case .invalid, .failure: "failure"
        case .success: "success"
        }
    }
}
