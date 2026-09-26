# Chess Endgame Trainer — Project Notes

## App 功能

- 可互動的王＋車 vs 王訓練
- Easy、Medium、Hard 黑王策略
- 點擊與拖曳移動、合法走法提示、將軍／將死／逼和判定
- 固定 seed 的每日挑戰
- SwiftData 訓練紀錄、成功率、各難度最佳步數與每日挑戰狀態
- 統計頁、王車王教學、音效與 haptic feedback

## 使用 AI 開發的階段

- Phase 1：棋規模型、規則引擎、局面評估、黑王策略與測試
- Phase 2：GameSession 與完整 SwiftUI 訓練流程
- Phase 3：設計系統、頁面 polish、素材生成與裝置驗證
- Phase 4：SwiftData、統計、字體、聲音、網路圖片與展示文件

## AI 生成素材

App Icon、首頁 hero、兩張教學插圖、每日挑戰、統計、成功與重試圖示由 OpenAI image generation 產生。棋盤由 SwiftUI 繪製；棋子不是 AI 生成。

## 開源素材

- Chessnut chess pieces，Alexis Luengas，Apache License 2.0
- 來源：https://github.com/LexLuengas/chessnut-pieces
- 完整授權文件：`ChessEndgameTrainer/ThirdParty/Chessnut/`

## Custom font

- Space Grotesk variable font
- The Space Grotesk Project Authors / Florian Karsten
- SIL Open Font License 1.1
- 來源：https://github.com/floriankarsten/space-grotesk
- 完整授權文件：`ChessEndgameTrainer/ThirdParty/SpaceGrotesk/`
- 用於標題與重要數字；內文維持系統字體。SwiftUI `relativeTo` 保留 Dynamic Type，載入失敗時由系統字體 fallback。

## 網路圖片

- 作品：Finished game of chess
- 作者：Airear
- 來源：https://commons.wikimedia.org/wiki/File:Finished_game_of_chess.jpg
- 授權：Creative Commons Attribution-ShareAlike 4.0
- App 使用 Wikimedia thumbnail URL，僅作為 Tutorial 的靈感區塊；包含 loading placeholder 與 failure fallback。

## 音效來源

`move.wav`、`check.wav`、`success.wav`、`failure.wav` 為本專案使用 FFmpeg sine-wave filters 自行合成的原創提示音，不含第三方錄音。

## 測試

共 31 個 Swift Testing 測試：原有 26 個棋規與 GameSession 測試，加上統計推導、SwiftData 儲存、跨 container 持久化、音效關閉及字體註冊測試。

## 已知限制

- 目前只支援王車王。
- 黑王策略不是 tablebase 最佳解。
- 未實作 fifty-move rule 與 repetition draw。
- 網路圖片離線時顯示 fallback，不做永久快取。
- 音效只有單一開關；haptic 目前固定開啟。
