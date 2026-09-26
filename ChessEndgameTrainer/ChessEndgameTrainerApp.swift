//
//  ChessEndgameTrainerApp.swift
//  ChessEndgameTrainer
//
//  Created by SungLa on 2026/9/26.
//

import SwiftUI
import SwiftData

@main
struct ChessEndgameTrainerApp: App {
    init() {
        AppFont.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TrainingRecord.self)
    }
}
