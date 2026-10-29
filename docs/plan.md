# CashRotate v1.0 實作計畫（草案，待確認）

2026-10-28 · 依據 CLAUDE.md 與《需求總結》

## 0. 現況

- 專案資料夾是空的，尚未 `git init`。
- 本機有 Java 21、git、gh、adb；**沒有 Flutter SDK，也沒有 Android SDK / Android Studio**。M0 開工前要先裝好（見 §5 決策 D1）。

## 決策結果（2026-10-28 定案）

- D1–D4、D6、D7：照 §5 建議。Flutter 裝在 `%USERPROFILE%\dev\flutter`；Android Studio 由你安裝。
- D5：**暫定閉源**。套件只選寬鬆授權（MIT、BSD、Apache-2.0、zlib），不引入 GPL 等 copyleft 套件，日後要用任何授權開源都不受限。
- 偏差 1、2、5：照建議。
- 偏差 3：免費版外幣項目用**手動輸入匯率**；Pro 才自動更新。
- 偏差 4：v1.0 Pro 進階報表 = 訂閱年度成本排行、價格歷史、信用卡額度使用率。

## 1. 架構與資料夾結構

採 Dart **pub workspace**（Dart 3.6+ 內建，不需 melos）：純 Dart 的領域層與同步層拆成獨立套件。好處是編譯期就禁止它們 import Flutter，單元測試用 `dart test` 跑得快，之後出 iOS 可原封不動沿用。

```
CashRotate/
├─ CLAUDE.md                     ← 從 Downloads 複製進來，之後每次對話自動載入
├─ pubspec.yaml                  ← workspace 根
├─ analysis_options.yaml         ← 全專案共用 lint
├─ .github/workflows/ci.yaml     ← 格式、靜態分析、測試
├─ docs/
│  ├─ plan.md                    ← 本文件
│  ├─ requirements.md            ← 《需求總結》副本
│  ├─ adr/0001-*.md …            ← 技術決定紀錄
│  └─ backlog.md                 ← 範圍外的新想法
├─ presets/                      ← 預設庫原始資料（社群經 GitHub 提交）
│  ├─ schema.json                ← JSON Schema，CI 驗證
│  ├─ global/*.json  tw/*.json  hk/*.json  templates/*.json
│  └─ tool/                      ← 讀音表（Unihan）與破音字詞組；建置工具在 packages/core/tool/build_presets.dart
├─ packages/
│  ├─ core/                      ← 純 Dart 領域層
│  │  └─ lib/src/
│  │     ├─ money/               ← Money（最小單位整數）、Currency 表（41 種）、格式化、符號歧義
│  │     ├─ fx/                  ← 匯率換算、手續費率、學習卡片加價
│  │     ├─ schedule/            ← 週期、錨定日、月底規則、價格階段引擎、Occurrence 展開
│  │     ├─ reminders/           ← 提醒「要在何時發什麼」的計算（不碰 Android）
│  │     ├─ ledger/              ← 交易、餘額、對帳、轉帳、自動入帳
│  │     ├─ reports/             ← 圖表資料彙總
│  │     ├─ import/              ← 脫敏、規則解析、AI 輸出驗證、去重
│  │     ├─ presets/             ← 預設庫模型、別名與拼音／注音首字母比對
│  │     └─ entitlements/        ← 免費 / Pro 權益旗標
│  └─ sync/                      ← 純 Dart 同步層
│     └─ lib/src/
│        ├─ hlc/                 ← 混合邏輯時鐘
│        ├─ changelog/           ← 欄位級變更、墓碑、合併、衝突判定
│        ├─ crypto/              ← 金鑰衍生、AEAD、檔案格式、復原碼（介面 + 實作）
│        ├─ webdav/              ← PROPFIND / PUT / MOVE / DELETE 用戶端
│        └─ engine/              ← 列序號、只下載新檔、快照、清理
└─ app/                          ← Flutter App（介面 + 資料層 + 原生）
   ├─ lib/
   │  ├─ main.dart  app.dart
   │  ├─ brand.dart              ← App 名稱與 applicationId 唯一出處（Gradle 也讀這裡）
   │  ├─ l10n/                   ← app_en.arb、app_zh_Hant.arb、app_zh.arb（簡體，zh 後備）、語系解析
   │  ├─ theme/                  ← 色票 token、淺 / 深色、珠光漸層、等寬數字
   │  ├─ layout/                 ← 視窗寬度級別、列表 / 詳情雙欄（避開摺痕）
   │  ├─ routing/                ← 路由表、自適應外殼（底部導覽 / 導覽軌）
   │  ├─ widgets/                ← 跑馬燈文字、狀態元件、金額文字（主要幣別大字＋原幣小字）、首字母徽章、幣別選擇器
   │  ├─ data/                   ← drift 資料表與遷移、Repository（項目、設定、匯率）、ChangeLog、預設庫載入
   │  ├─ platform/               ← platform channel 的 Dart 端包裝
   │  └─ features/
   │     ├─ home/  items/  onboarding/  ledger/  accounts/
   │     └─ reports/  import/  sync/  security/  settings/
   ├─ android/app/src/main/kotlin/<package>/
   │  ├─ reminders/              ← AlarmManager 不精確鬧鐘、WorkManager 每日補檢、BootReceiver、通知操作
   │  ├─ widget/                 ← 桌面小工具（M7 前）
   │  ├─ keystore/               ← Keystore 包裝（資料庫金鑰、AI Key）
   │  └─ share/                  ← 接收分享文字
   ├─ test/                      ← widget 與 golden 測試
   └─ integration_test/
```

分層規則：`core` 不依賴任何套件以外的東西；`sync` 只依賴 `core`；`app` 依賴兩者。介面不直接碰 drift，只經 Repository。

## 2. 建議的套件（加入前會逐一再確認維護狀態與授權，並寫 ADR）

| 用途 | 建議 | 理由 |
| --- | --- | --- |
| 狀態管理 | Riverpod 3（不用程式碼產生） | 不依賴 BuildContext，Repository / 引擎可直接注入與在測試中覆寫；非同步狀態（資料庫 stream、匯率）處理成熟；作者持續維護 |
| 路由 | go_router | Flutter 官方團隊維護；支援 ShellRoute 做自適應外殼、深連結（通知點擊進詳情） |
| 資料庫 | drift + SQLCipher | 型別安全查詢、stream 監聽、遷移工具與測試支援完整；SQLCipher 版 sqlite 編譯方式要在 M1 確認（sqlite3 套件近期改用 build hooks） |
| 多語系 | flutter_localizations + intl（gen-l10n） | 官方方案，ARB + ICU 複數 |
| Lint | flutter_lints + 另加嚴格規則 | 官方基礎，不引入過嚴的文件規則 |
| 原生通知 / 排程 | 直接寫 Kotlin（AlarmManager、WorkManager、NotificationCompat） | 規格要求原生；不經第三方 Flutter 外掛，可完全控制廠商相容性 |
| 加密 | 見決策 D3 | |

刻意不用：freezed 等大量程式碼產生（Dart 3 的 sealed class / record 已足夠，只保留 drift 的產生器）。

## 3. 關鍵設計（M1 / M5 會各寫 ADR）

- **金額**：`int` 最小貨幣單位（Dart 原生 64 位元）。匯率不用浮點，存十進位字串，換算用十進位運算後依 ISO 4217 四捨五入。
- **時間**：事件時間（建立、修改、交易時刻、提醒送達）存 UTC 毫秒。**到期日、扣款日、paidUntil 這類「日曆日」存不帶時區的日期（yyyy-MM-dd）**，提醒時刻依當下時區算出。這樣時區變更或出國時，繳費日不會跑到前一天或後一天。（與 CLAUDE.md「時間以 UTC 儲存」略有不同，見 §6 偏差 1）
- **ID**：UUIDv7（時間有序、各裝置離線產生不衝突）。
- **同步**：每次寫入同時記一筆欄位級 ChangeLog（實體、ID、欄位、新值、HLC）。合併規則照 CLAUDE.md。
- **資料庫金鑰**：首次啟動產生 256 位元隨機金鑰，用 Keystore 中不可匯出的 AES 金鑰加密後存在 App 私有目錄。
- **同步金鑰階層（建議）**：隨機產生「資料金鑰」加密所有檔案；資料金鑰分別用「同步密碼（Argon2id）」與「復原碼」各包一份存在 manifest。好處：改密碼不必重新加密雲端全部檔案，復原碼能獨立解鎖。（見 §6 偏差 2）
- **雲端檔案格式**：`魔數 + 格式版本 + nonce + 密文`；明文為 gzip 壓縮的 JSON Lines；附加認證資料 = 檔案路徑 + 標頭。
- **權益**：`Entitlements` 介面先做，免費 / Pro 的判斷集中在一處；M7 才接 Play Billing。

## 4. 里程碑任務

### M0 骨架（確認本計畫後開始）
1. 安裝 / 確認工具鏈（Flutter 穩定版、Android SDK 36、模擬器）
2. `git init`、`.gitignore`、複製 CLAUDE.md 與需求文件進專案
3. 建 workspace：`app`（applicationId 用暫定值、集中設定）、`packages/core`、`packages/sync`
4. Android 設定：minSdk 26、targetSdk 36、不鎖方向、可調整大小
5. lint 與 `dart format` 規則；GitHub Actions：格式、分析、`flutter test`、`dart test`
6. ARB 三語 + gen-l10n，複數範例；地區格式化（幣別、日期、一週起始日）工具
7. 主題：色票 token、淺 / 深色、珠光漸層元件（「減少動態」時停用）、等寬數字
8. 自適應導覽外殼：< 600 底部導覽；600–840 導覽軌 + 列表 / 詳情雙欄；≥ 840 雙欄 + 儀表板骨架；摺痕偵測避開分隔線；旋轉 / 摺疊保留狀態
9. 跑馬燈文字元件（含「減少動態」改換行）
10. Golden 測試基礎：5 種寬度 × 3 種字體倍率 × 淺 / 深色的測試輔助工具
11. ADR 0001（workspace 結構）、0002（狀態管理與路由）

### M1–M7
依 CLAUDE.md 里程碑，每個開始前再列細部任務清單給你。

## 5. 需要你決定的事（之後很難改）

| # | 決策 | 選項 | 我的建議 | 何時需要 |
| --- | --- | --- | --- | --- |
| D1 | 工具鏈安裝 | (a) 你裝 Android Studio（含 SDK 36、模擬器，授權條款需你本人同意），我用 git 裝 Flutter 穩定版並設定 PATH (b) 兩者都由你裝 | (a) | 現在 |
| D2 | 狀態管理與路由 | (a) Riverpod 3 + go_router (b) Bloc + go_router | (a)，理由見 §2 | M0 |
| D3 | 加密函式庫 | (a) libsodium（2017 年經審計，Argon2id 與 XChaCha20-Poly1305 一應俱全，iOS 也可用），透過 Dart FFI 綁定；若現成綁定套件已不維護，就自行用 ffigen 寫一層薄綁定 (b) Google Tink（AES-256-GCM / XChaCha20-Poly1305，維護最積極，但沒有 Argon2，需另配 BouncyCastle，且只能在 Kotlin 端，iOS 要重寫） (c) 純 Dart `cryptography` 套件（未經審計，Argon2 在低階機很慢） | (a)，演算法用 XChaCha20-Poly1305（隨機 nonce 不怕碰撞） | M5，但最好早定 |
| D4 | Argon2id 參數 | (a) 記憶體 64 MiB、3 次迭代、平行度 1（低階 3 GB 機約 0.5–1 秒） (b) 256 MiB、3 次（libsodium「MODERATE」，較安全但低階機可能 3 秒以上或記憶體不足） | (a)；參數寫在 manifest，之後可升級 | M5 |
| D5 | 是否開源與授權 | (a) 閉源 (b) GPLv3 開源（可上 F-Droid，社群翻譯容易；Pro 仍可在 Play 收費） (c) Apache-2.0 / MIT 開源 | 你的商業決定；影響能用哪些授權的套件、F-Droid 版要拿掉 Play Billing | M0（決定可接受的套件授權） |
| D6 | 同步明文格式 | (a) gzip + JSON Lines（好除錯） (b) CBOR（較小，較難人工檢查） | (a)；檔案有格式版本號，之後可換 | M5 |
| D7 | applicationId | 例如 `com.<你的網域>.cashrotate`；上架後不能改 | 先用暫定值集中設定，上架前你給正式值 | M7 前 |

## 6. 與規格的偏差 / 需要你釐清

1. **日曆日不存 UTC**（§3）：到期日類欄位存純日期，否則時區變更會讓繳費日偏移一天。建議採用。
2. **manifest 內放「被加密包起來的資料金鑰」**：CLAUDE.md 寫「裝置清單（不含金鑰）」。包裝後的金鑰沒有密碼或復原碼解不開，不算洩漏金鑰；但若你要求 manifest 完全不含任何金鑰材料，則改密碼時必須重新加密雲端全部檔案。請確認可接受建議做法。
3. **免費版的多幣別**：Pro 含「自動匯率」，那免費版新增外幣項目時的「≈ 主要幣別金額」要用什麼匯率？建議：免費版可手動輸入匯率，或首次取得一次後不再自動更新——請選一種。
4. **「進階報表」(Pro) 在 v1.0 的內容未定義**：v1.0 必做只有基本圖表。建議 v1.0 的 Pro 進階報表 = 訂閱年度成本排行 + 價格歷史 + 信用卡額度使用率（需求總結有列）；或 v1.0 先不放、只顯示鎖定。
5. **需求總結有、但 CLAUDE.md 沒說做或不做的項目**，建議歸屬如下，請確認：
   - 納入 v1.0（屬於已列功能的一部分）：交易附件（資料模型已有）、子分類、交易搜尋篩選、拼音 / 注音首字母搜尋、信用卡結帳後自動產生繳卡費、貸款每期自動更新剩餘期數與本金、`FLAG_SECURE` 選項、App 離開多久後上鎖
   - 放 backlog：資源回收桶、匯出 .ics / 寫入行事曆、通知欄快速記帳、App 捷徑、淨資產折線、日曆熱力圖、OpenRouter OAuth 登入
6. **預設庫 200～300 項**：我會依格式整理首批資料，但取消連結與別名（尤其銀行帳單商號）需要你或社群抽查；品牌色只用公開資訊，不放商標。
7. **WebDAV 實測**（Nextcloud、群暉、堅果雲、InfiniCLOUD）到 M5 需要你提供測試帳號，或你在自己的環境跑我寫好的測試腳本。
8. **Golden 測試**：字型渲染在 Windows 與 Linux 不同，基準圖統一在 CI（Linux）產生，本機只比對 CI 產出的圖。
