import SwiftUI

struct TutorialView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    header
                    ForEach(TutorialLesson.lessons) { lesson in
                        TutorialLessonCard(lesson: lesson)
                    }
                    closingTip
                    ChessInspirationCard()
                }
                .padding(20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("王車王教學")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("TutorialCutSpace")
                .resizable()
                .scaledToFill()
                .frame(height: 190)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.largeRadius))
            Text("四步建立將死框架")
                .font(AppFont.title(.largeTitle))
                .foregroundStyle(AppTheme.primaryText)
            Text("重點不是一直將軍，而是安全地縮小黑王能活動的空間。")
                .font(.body)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var closingTip: some View {
        Label(
            "練習時每走一步都問自己：黑王的空間變小了嗎？我的車安全嗎？白王有更靠近嗎？",
            systemImage: "checkmark.seal.fill"
        )
        .font(.subheadline.weight(.medium))
        .foregroundStyle(AppTheme.primaryText)
        .appCard()
    }
}

private struct ChessInspirationCard: View {
    private let imageURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Finished_game_of_chess.jpg/960px-Finished_game_of_chess.jpg")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("棋盤上的終局")
                .font(AppFont.title(.title3))
                .foregroundStyle(AppTheme.primaryText)
            AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    NetworkImageFallback(icon: "wifi.exclamationmark", message: "圖片暫時無法載入")
                case .empty:
                    NetworkImageFallback(icon: "photo", message: "載入公開圖片中…", showsProgress: true)
                @unknown default:
                    NetworkImageFallback(icon: "photo", message: "圖片暫時無法載入")
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallRadius))

            Text("〈Finished game of chess〉，Airear，Wikimedia Commons，CC BY-SA 4.0。")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .appCard()
    }
}

private struct NetworkImageFallback: View {
    let icon: String
    let message: String
    var showsProgress = false

    var body: some View {
        ZStack {
            AppTheme.elevatedBackground
            VStack(spacing: 9) {
                if showsProgress {
                    ProgressView().tint(AppTheme.accent)
                } else {
                    Image(systemName: icon).font(.title2).foregroundStyle(AppTheme.secondaryText)
                }
                Text(message).font(.caption).foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

private struct TutorialLessonCard: View {
    let lesson: TutorialLesson

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Text("\(lesson.step)")
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.background)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.accent, in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text(lesson.title)
                        .font(AppFont.title(.title3))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(lesson.explanation)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if lesson.step == 2 {
                Image("TutorialKingSupport")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallRadius))
                    .accessibilityLabel("白王靠近支援的概念插圖")
            }

            ChessBoardView(position: lesson.position, isInteractive: false)
                .frame(maxWidth: 270)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("\(lesson.title)示意棋盤")

            Label(lesson.tip, systemImage: "lightbulb.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.warning)
        }
        .appCard()
    }
}

private struct TutorialLesson: Identifiable {
    let id: Int
    let step: Int
    let title: String
    let explanation: String
    let tip: String
    let position: ChessPosition

    static let lessons: [TutorialLesson] = [
        TutorialLesson(
            id: 1,
            step: 1,
            title: "車先切割空間",
            explanation: "把車放到黑王無法越過的橫線或直線，先把棋盤切成兩區。不要急著連續將軍。",
            tip: "每次移動車，都要確認黑王下一步碰不到它。",
            position: .kingRookKing(
                whiteKing: Square(file: 1, rank: 1),
                whiteRook: Square(file: 4, rank: 3),
                blackKing: Square(file: 6, rank: 6)
            )
        ),
        TutorialLesson(
            id: 2,
            step: 2,
            title: "白王靠近支援",
            explanation: "車建立界線後，用白王朝黑王走近。兩王不能相鄰，但白王能奪走黑王周圍的逃生格。",
            tip: "理想狀態是兩王隔著一格對峙。",
            position: .kingRookKing(
                whiteKing: Square(file: 3, rank: 4),
                whiteRook: Square(file: 1, rank: 2),
                blackKing: Square(file: 5, rank: 6)
            )
        ),
        TutorialLesson(
            id: 3,
            step: 3,
            title: "避免車被黑王吃",
            explanation: "沒有白王保護時，車不要停在黑王旁邊。若黑王逼近，先把車移到遠端，再繼續靠王。",
            tip: "下車的每一步，都先掃描黑王的八個鄰格。",
            position: .kingRookKing(
                whiteKing: Square(file: 2, rank: 2),
                whiteRook: Square(file: 5, rank: 1),
                blackKing: Square(file: 5, rank: 4)
            )
        ),
        TutorialLesson(
            id: 4,
            step: 4,
            title: "在邊線完成將死",
            explanation: "把黑王推到最外圈後，讓白王控制向內的三個逃生格，再用車沿邊線將軍。",
            tip: "最後一手將軍前，確認黑王沒有任何未被控制的鄰格。",
            position: .kingRookKing(
                whiteKing: Square(file: 2, rank: 6),
                whiteRook: Square(file: 0, rank: 0),
                blackKing: Square(file: 0, rank: 7),
                sideToMove: .black
            )
        )
    ]
}
