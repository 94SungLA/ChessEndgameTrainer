# AI Development Log

這份文件整理 Chess Endgame Trainer 從構想到可展示產品的 AI 協作歷程。重點不是只列出完成品，而是保留「使用者如何下 prompt、Codex 如何拆解工作、實作後出現什麼問題，以及下一輪如何用更精確的 prompt 修正」。

> 紀錄說明：本文件只引用目前 conversation 中可確認的內容。若早期 Codex 回覆或工具輸出沒有完整保留，會明確標示為「摘要」，不把推測寫成逐字紀錄。

## 1. Initial Planning

最初的想法來自一個具體學習痛點：使用者的西洋棋基礎殘局不夠穩定，尤其是「王＋車 vs 王」，因此希望做出一個真的能練習，而不是只有靜態畫面的 SwiftUI App。

最初 `/plan` 的範圍包含：

- 首頁、殘局選擇、棋盤訓練、結果回饋與教學頁。
- 棋子可點擊或拖曳，並限制合法走法。
- 黑王能自動回應。
- 能判斷將軍、將死、逼和、非法走法與車被吃。
- 記錄步數並提供簡短提示。
- 架構上保留王后王、王兵王、升變殘局的擴充能力，但第一版只完成王車王。
- 視覺採深色、現代、乾淨的 chess app 方向。
- 規劃 App Icon、棋子、插圖、字體、音效、haptic、每日挑戰與統計等產品化元素。

### Codex 的整體規劃（摘要）

早期規劃回覆的逐字內容在目前 conversation 中沒有完整保留；從後續被接受並執行的 phase 可以確認，整體工作被拆成以下層次：

1. 先建立與 UI 無關的 Chess Core，包括資料模型、規則引擎、局面評估、黑王策略與可重現的局面產生器。
2. 再以 `GameSession` 封裝單局狀態，讓 SwiftUI View 不直接重寫棋規。
3. 完成可玩的 Home → Selection → Training → Result／Tutorial 流程。
4. 修正棋盤 layout 後，再進行棋子素材與整體視覺 redesign。
5. 最後加入 custom font、聲音、haptic、SwiftData、Statistics 與展示文件。

### 重要決策

- 第一個可交付版本只做王車王，不因未來擴充而提前實作其他殘局。
- Chess Core 與 SwiftUI UI 分離，規則不能散落在 View 裡。
- `PositionGenerator` 從一開始支援固定 seed，為每日挑戰留下基礎。
- 50-move rule 與 repetition 保留擴充點，但不阻塞第一階段。
- 棋盤必須以 SwiftUI 繪製，不能用靜態圖片取代互動棋盤。
- 初期曾規劃以 AI 生成素材為主；後來經過實際視覺評估，棋子改採授權清楚的開源素材，AI generation 只負責品牌與輔助插圖。

### 代表性原始 prompt

> 我想做一個 iOS App，名稱叫「Chess Endgame Trainer」，使用 SwiftUI 開發。這個 App 的出發點是我自己的西洋棋基礎殘局不太穩，尤其是王車王，所以想把它做成一個真的可以拿來練習的殘局訓練工具，而不是只有展示畫面的 demo。
>
> 我希望整體風格是現代、乾淨、偏深色、有一點 chess app 的質感，但不要太像系統預設 UI。

## 2. Phase 1 — Chess Core

Phase 1 的目標是先證明棋規與局面邏輯可靠，不急著做完整 UI。

### 使用者要求

使用者指定先完成：

- `ChessModels`
- `ChessRulesEngine`
- `PositionEvaluator`
- `BlackKingStrategy`
- `PositionGenerator`
- 規則與 edge cases 測試

王車王必須正確處理：王的合法移動、雙王不能相鄰、王不能走進被攻擊格、車的直線移動與阻擋、黑王合法吃車、將軍、將死、逼和、車被吃及合法走法生成。

### 實作結果

`ChessModels` 定義棋子顏色、種類、棋盤座標、棋子、行棋與局面。`ChessRulesEngine` 成為規則的唯一來源，負責產生合法走法、套用走法、判斷攻擊格與終局結果。

`PositionEvaluator` 提供局面評估能力，讓黑王策略能比較候選走法。`BlackKingStrategy` 完成 Easy、Medium、Hard 三個層級；它不是 tablebase 最佳解，但每個難度都只會選擇合法走法。`PositionGenerator` 能產生合法且仍可玩的王車王起始局面，並以 seed 保證同一輸入得到同一局面。

測試涵蓋主要 edge cases，Phase 1 驗證結果為 **21 passed**。

### 問題與處理

使用者希望若過程中曾遇到 linker 或 test target 問題也要記錄；但目前可取得的 conversation 沒有保留一段可核對的 linker-error prompt 或完整錯誤輸出，因此不能把它寫成已確認事件。可以確認的是 Phase 1 最後完成 build 與測試驗證，後續 Phase 2 是在「21 個測試已通過」的基礎上繼續。

## 3. Phase 2 — Playable App

Phase 2 把 Chess Core 接成可實際操作的 SwiftUI App，但仍只做王車王。

### 頁面與流程

- `HomeView`：標題、介紹、開始訓練、每日挑戰、教學與統計預留區。
- `EndgameSelectionView`：王車王可選 Easy／Medium／Hard；其他殘局只顯示 Coming Soon。
- `TrainingView`：8×8 棋盤、點擊選取、目的格提示、非法操作回饋、拖曳移動、黑王自動回應與輸入鎖定。
- `TutorialView`：說明切割空間、白王支援、保護車與邊線將死。
- `TrainingResultView`：顯示將死成功、逼和或車被吃，並提供步數、教學回饋、重新挑戰及回首頁。

### GameSession

`GameSession` 使用 `@MainActor` 與 `@Observable` 管理一局遊戲。它負責：

- 棋子選取與合法目的格。
- `attemptMove` 與拖曳移動。
- 玩家步數。
- 黑王延遲回應與輸入鎖定。
- feedback、last move 與 game outcome。
- restart 與取消 pending response。

這個分層讓 View 只顯示狀態並轉送操作，不需要知道 `ChessRulesEngine` 的細節。

Phase 2 補上 GameSession 核心測試後，測試數量成長為 **26 / 26 passed**。

## 4. UI Layout Failure and Fix

這是整個開發過程中最明顯、也最適合展示「AI 實作並非一次成功」的案例。

### 失敗狀態

初版 `TrainingView` 雖然能編譯與互動，但畫面出現嚴重 layout 問題：

- 8×8 棋盤沒有完整顯示。
- 棋盤被裁切，只剩右下或局部區域。
- 棋子跟著被切掉。
- `ChessBoardView` 周圍有大量不合理空白。
- 棋盤沒有置中，尺寸也沒有正確回應父容器。
- 訓練頁的視覺重心錯誤，最重要的棋盤反而太小。

### 使用者如何修正 prompt

使用者沒有只要求「把 padding 調一下」，而是明確指出需要重新檢查 constraint 的來源：`GeometryReader`、`frame(maxWidth/maxHeight)`、`aspectRatio`、`clipping`、alignment、grid spacing，以及父容器是否提供錯誤高度。

### Codex 的修正

修正方向是移除會吞掉多餘高度、又依賴父層高度推算正方形的棋盤 layout，改為：

- 使用固定 8 欄、spacing 為 0 的 `LazyVGrid`。
- 每個棋格個別維持 `aspectRatio(1, contentMode: .fit)`。
- 整張棋盤再維持 1:1 aspect ratio。
- 由可用寬度決定棋盤大小，不用不可靠的父層高度。
- 保留 iPhone 水平 margin，並限制大螢幕最大寬度。
- 讓棋盤成為 Training 頁面的主要內容，精簡上方狀態卡並把提示移到棋盤下方。

修正後在 iPhone Simulator 實測，棋盤約為 370×371 pt，64 格完整存在，棋子沒有裁切。

### 這次迭代學到什麼

1. 「能 build」不代表 UI 正確；視覺結果必須在實際 simulator 尺寸驗證。
2. `GeometryReader` 不是自動解決 responsive layout 的工具。如果父容器提供過大或不明確的高度，它反而可能放大問題。
3. 棋盤這類固定比例元件，應讓寬度主導尺寸，再以 aspect ratio 推導高度。
4. 有效的修正 prompt 應描述觀察到的症狀、應檢查的 constraint 來源，以及不可接受的修法，例如「不要用 magic number 局部補丁」。

## 5. Phase 3 — Visual Redesign

棋盤 layout 修正後，下一個問題是棋子仍使用 Unicode／emoji chess glyph，視覺上像 prototype。

### 素材策略的改變

一開始曾要求以 image generation 產生白王、白車、黑王；之後使用者重新評估成本與一致性，決定不要浪費生成資源製作整套棋子，而是：

- 棋子採用授權清楚的開源 flat chess set。
- 最終選用 **Chessnut Pieces**，作者 Alexis Luengas，Apache License 2.0。
- 專案保留完整黑白棋子 SVG，王車王目前使用 `ChessWhiteKing`、`ChessWhiteRook`、`ChessBlackKing`。
- 來源、作者與授權存放於 `ThirdParty/Chessnut/`。

AI generation 集中在更能呈現產品識別的項目：

- App Icon
- `HomeHero`
- `TutorialCutSpace`
- `TutorialKingSupport`
- `DailyChallengeArt`
- `ResultSuccessArt`
- `ResultRetryArt`
- `StatisticsArt`

### Flat modern design direction

- 深藍黑／charcoal 背景。
- 翡翠綠與克制的暖金色作為重點色。
- 幾何、乾淨、高辨識度的圖像。
- 少量漸層、細邊框、卡片化資訊。
- 避免 medieval、過度寫實、可愛貼圖及大量 glassmorphism。
- TrainingView 仍以棋盤為主，裝飾不能搶走操作焦點。

`HomeView`、`EndgameSelectionView`、`TrainingView`、`TutorialView`、`TrainingResultView` 都完成視覺統一。Simulator 曾發現 Home hero 的 intrinsic width 把 ScrollView 撐寬；後來使用受父容器寬度約束的 `GeometryReader` 修正，重新驗證後頁面回到 402 pt 畫面範圍內。

Phase 3 最終 build 成功，既有 **26 / 26 tests passed**。

## 6. Phase 4 — Product Polish

Phase 4 的目的不是新增棋種，而是補齊作業展示與產品完整度。

### Custom font

加入 **Space Grotesk Variable**：

- 作者／專案：The Space Grotesk Project Authors、Florian Karsten。
- 授權：SIL Open Font License 1.1。
- 標題與重要數字使用 custom font，內文維持系統字體。
- `Font.custom(..., relativeTo:)` 保留 Dynamic Type。
- 使用 CoreText 從 App bundle 註冊，並保留系統 fallback。

過程中測試曾發現原先使用的 PostScript name 不正確，`UIFont(name:)` 回傳 `nil`。Codex 實際檢查註冊後的 font names，改用 variable font 暴露的 `SpaceGrotesk-Light_Bold` 與 `SpaceGrotesk-Light_Medium`，測試才通過。

### 音效與 haptic

加入 `move.wav`、`check.wav`、`success.wav`、`failure.wav`。這些聲音以 FFmpeg sine-wave filters 在專案中自行合成，不依賴第三方錄音。

`FeedbackService` 對合法落子、非法操作、將軍、成功與失敗提供對應 haptic，並使用 `AVAudioPlayer` 播放短音效。音效開關透過 `@AppStorage` 保存；關閉後不建立或啟動播放器。

### SwiftData persistence

新增單一 `TrainingRecord` schema，保存：

- 完成時間
- 難度
- 結果
- 玩家步數
- 是否為每日挑戰
- 每日挑戰 ID

總練習次數、成功次數、成功率、各難度最佳步數、今日完成狀態、今日最佳步數與最近紀錄都從單局紀錄推導，避免重複儲存統計造成不同步。

### StatisticsView 與首頁真實資料

首頁 placeholder 被真實資料取代。`StatisticsView` 顯示總訓練、成功率、成功局數、各難度最佳步數、今日挑戰與最近八次紀錄，並沿用 Phase 3 設計系統。

### 網路圖片

Tutorial 加入 Wikimedia Commons 的〈Finished game of chess〉：

- 作者：Airear。
- 授權：CC BY-SA 4.0。
- 使用 `AsyncImage`。
- 具 loading placeholder 與 failure fallback。
- 網路圖片不影響主要訓練流程。

### 展示文件與驗證

新增 `PROJECT_NOTES.md`，整理功能、AI 開發階段、素材、授權、字體、網路圖片、聲音、測試與限制。

測試新增 SwiftData insert／fetch、統計推導、音效關閉、persistent store 重建與字體註冊，最終為 **31 / 31 passed**。

Simulator 實際走過 Home → Easy → Training →「白車被吃」Result → Home → Statistics；冷啟動後仍保留訓練紀錄與音效設定。每日挑戰跨啟動的特定資料則由實際 on-disk SwiftData container restart 測試驗證。

## 7. Representative Prompts

以下挑選 conversation 中最能代表需求演進的 prompts。長 prompt 為避免重複，部分保留關鍵段落；有標示「摘要」者不是逐字全文。

### Prompt 1 — Initial `/plan`

> 我想做一個 iOS App，名稱叫「Chess Endgame Trainer」，使用 SwiftUI 開發。
>
> 這個 App 的出發點是我自己的西洋棋基礎殘局不太穩，尤其是王車王，所以想把它做成一個真的可以拿來練習的殘局訓練工具，而不是只有展示畫面的 demo。
>
> 請先檢查目前 Xcode 專案結構，然後幫我規劃一個完整但實際可執行的開發計畫。這一步先不要修改任何檔案。

### Prompt 2 — Phase 1 Chess Core

> 先執行 Phase 1：Chess Core。這一階段先不要做完整 UI，也不要急著加入統計、音效、動畫或素材。
>
> 王車王需要能正確處理：王的合法移動、雙王不能相鄰、王不能走進被攻擊格、車的直線移動與阻擋、黑王合法吃車、將軍、將死、逼和、車被吃、合法走法生成。
>
> 同時建立測試，至少覆蓋上述規則的主要 edge cases。

### Prompt 3 — Phase 2 Playable App（摘要）

> Phase 1 驗證完成，接下來進行 Phase 2：把王車王做成完整可玩的 UI 流程。
>
> TrainingView 要顯示 8x8 棋盤、支援點擊與拖曳、顯示合法走法、提供非法回饋、讓黑王自動回應，並連接既有 ChessRulesEngine / BlackKingStrategy / PositionGenerator，不要在 View 重寫棋規。
>
> 使用 @Observable / MainActor 的 GameSession 管理單局狀態，並補上核心測試，不要破壞 Phase 1 的 21 個測試。

### Prompt 4 — Layout bug 修復

> 目前 TrainingView 的 layout 明顯壞掉了，請先不要繼續加功能。
>
> 從目前畫面可以看到：棋盤沒有完整顯示 8x8、棋盤被裁切，只剩右下部分、棋子被切掉、ChessBoardView 外面有大量不合理空白、棋盤沒有置中、棋盤尺寸和父容器比例明顯錯誤。
>
> 這一輪只處理 TrainingView 與棋盤 layout，不要新增其他功能。目前這個畫面不接受「局部修補」，請從 layout constraints 的來源重新整理，而不是只調幾個 padding 或 frame 數值。

### Prompt 5 — 棋子 prototype 問題

> 目前棋盤 layout 已修好，但棋子仍然使用 emoji / Unicode chess glyph，整體質感太差，像 prototype。
>
> 請進行下一步：把目前的棋子顯示方式改成真正的素材資產，不要再用文字或 emoji。

### Prompt 6 — Phase 3 素材策略與視覺 redesign（摘要）

> 棋子不要用 AI 全部重生成。請使用授權清楚、可用於學生作品或可商用的開源扁平風格棋子素材。
>
> 請把 AI 生成資源集中在 App Icon、首頁 hero、教學插圖、結果狀態、每日挑戰與統計素材。
>
> 請真正建立一套一致的 UI system 與 asset strategy，不要只用幾個 padding / frame 微調來假裝完成視覺升級。

### Prompt 7 — Phase 4 Product Polish（摘要）

> Phase 3 視覺升級已完成，接下來進行 Phase 4：完成作業展示與產品完整度。
>
> 請完成 custom font、音效與 haptic、SwiftData 持久化、StatisticsView、合理的網路圖片使用情境，以及 PROJECT_NOTES.md。
>
> App build 成功，所有既有 26 個測試保持通過，並為持久化與統計邏輯加入必要測試。

> Linker error prompt 說明：目前 conversation 沒有可核對的獨立 linker-error user prompt，因此沒有虛構加入本節。

## 8. Development Timeline

| Stage | Main Goal | Result |
| --- | --- | --- |
| Initial Planning | 把王車王學習需求拆成可執行的 SwiftUI 產品計畫 | 確立 Chess Core → Playable UI → Visual Polish → Product Polish 的 phase 架構 |
| Phase 1 | 建立與 UI 分離的王車王規則核心 | Rules、Evaluator、3-level Strategy、seeded Generator；21 tests passed |
| Phase 2 | 完成可實際操作的 App 流程 | Home、Selection、Training、Tutorial、Result、GameSession；26 / 26 passed |
| Layout Fix | 修正棋盤裁切、錯誤比例與空白 | 改以寬度主導的 1:1 `LazyVGrid`；Simulator 顯示完整 64 格 |
| Phase 3 | 建立正式產品視覺與素材策略 | Chessnut SVG 棋子、AI 品牌素材、統一 dark flat design；26 / 26 passed |
| Phase 4 | 加入資料、聲音、字體與展示完整度 | Space Grotesk、audio/haptic、SwiftData、Statistics、AsyncImage、文件；31 / 31 passed |

## 9. Final Reflection

### AI 最適合幫助的工作

- 把大型需求拆成可驗證的 phase，先解決風險最高的棋規，再處理 UI。
- 快速建立資料模型、規則引擎與大量 edge-case 測試。
- 在 SwiftUI、SwiftData、AVFAudio、CoreText 等框架之間完成整合。
- 根據明確視覺方向建立 design system、資產命名與頁面結構。
- 反覆執行 build、tests 與 Simulator 驗證，並用實際結果修正實作。
- 整理第三方素材來源與授權，降低作品展示時的授權風險。

### 仍需要人工判斷的地方

- 哪些功能對第一版真正重要，哪些應延後，不能只依「能不能做」決定。
- 棋子、hero、卡片與棋盤之間的質感是否符合產品定位。
- UI 在真實裝置上的視覺重心、留白與可讀性。
- AI 生成素材是否值得使用；棋子最後改採開源 SVG，就是人工重新評估一致性、授權與生成成本後的決策。
- 作業文章要呈現哪些失敗與取捨，而不只是展示成功結果。

### 最明顯的 AI 失敗案例

最明顯的失敗是初版 TrainingView layout。功能已存在，但 `GeometryReader`、父層高度與棋盤 frame 的組合造成棋盤裁切、錯位及大片空白。這個問題不是編譯器或 unit test 能發現的，而是需要人看到 simulator 畫面後指出。

另一個較小但具代表性的問題是 custom font 的 PostScript name。檔案已被打包，build 也成功，但初始名稱無法建立 `UIFont`。加入實際註冊測試並列出 runtime font names 後，才找到 variable font 真正暴露的名稱。

### 如何透過 prompt 與迭代修正

有效的修正並不是只說「看起來不好」，而是：

1. 列出具體症狀，例如裁切方向、空白、未置中與父容器比例錯誤。
2. 指定應重新檢查的技術來源，例如 `GeometryReader`、`aspectRatio`、alignment 與 grid spacing。
3. 限制 scope，例如只修 TrainingView，不順便加入新功能。
4. 明確排除不可接受的做法，例如不使用 magic number 假修正。
5. 要求 build、tests 與 simulator 三層驗證，而不是只看程式碼。

### 最終 App 相較最初構想增加的內容

最終版本不再只是可移動棋子的 SwiftUI demo，而包含完整的王車王規則、三種難度、seeded daily challenge、互動棋盤、拖曳、提示、結果教學、開源棋子、AI 品牌素材、custom font、音效、haptic、SwiftData 統計、網路圖片、素材授權文件，以及 31 個自動測試。

同時，這次開發保留了 Early Playable、Layout Bug、Fixed Pre-polish 三個階段的同尺寸 Simulator 截圖，可在 Medium 文章中直接呈現 AI 協作從初版、失敗、修正到產品化的演進。
