//
//  ContentView.swift
//  ChessEndgameTrainer
//
//  Created by SungLa on 2026/9/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var path: [AppRoute] = []
    @Query(sort: \TrainingRecord.completedAt, order: .reverse) private var records: [TrainingRecord]

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onStartTraining: { path.append(.endgameSelection) },
                onDailyChallenge: { path.append(.training(.dailyChallenge())) },
                onOpenTutorial: { path.append(.tutorial) },
                onOpenStatistics: { path.append(.statistics) },
                records: records
            )
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .endgameSelection:
            EndgameSelectionView { difficulty in
                path.append(.training(.practice(difficulty: difficulty)))
            }
        case .training(let configuration):
            TrainingFlowView(
                configuration: configuration,
                onReturnHome: { path.removeAll() }
            )
        case .tutorial:
            TutorialView()
        case .statistics:
            StatisticsView(records: records)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TrainingRecord.self, inMemory: true)
}
