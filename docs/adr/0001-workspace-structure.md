# 0001 Pub workspace：app + core + sync

- 狀態：已採用（2026-10-28）
- 決策者：專案擁有者確認計畫 §1

## 背景

領域邏輯（週期、價格階段、匯率、脫敏）與同步邏輯（HLC、合併、加密）需要大量單元測試，未來也要給 iOS 沿用。若和 Flutter 介面混在同一個套件，很容易不小心依賴 Flutter，測試也必須用較慢的 `flutter test` 跑。

## 決定

使用 Dart 3.6 起內建的 pub workspace（根目錄 `pubspec.yaml` 的 `workspace:`），不另裝 melos：

| 成員 | 套件名 | 內容 | 可依賴 |
| --- | --- | --- | --- |
| `packages/core` | `cashrotate_core` | 純 Dart 領域層 | 無 |
| `packages/sync` | `cashrotate_sync` | 純 Dart 同步層 | core |
| `app` | `cashrotate` | Flutter 介面、drift 資料層、Kotlin 原生 | core、sync |

- 套件名加前綴，因為 `sync` 是 Dart 保留字，不能當套件名。
- 全部成員共用根目錄 `analysis_options.yaml`。core 和 sync 沒有宣告 Flutter 依賴，所以 lint `depend_on_referenced_packages` 會擋住它們 import Flutter。
- workspace 共用一份版本解析，Flutter SDK 會釘住 `test_api`，所以純 Dart 套件的 `test` 版本限制寫 `any`。
- App 名稱與 applicationId 只寫在 `app/lib/brand.dart`；`android/app/build.gradle.kts` 用 regex 讀取，Android 標籤透過 `manifestPlaceholders` 帶入。Kotlin namespace 固定為 `app.cashrotate`，不隨 applicationId 改變。

## 影響

- 根目錄執行 `flutter pub get`、`flutter analyze`；core 和 sync 進各自資料夾執行 `dart test`。
- 新增成員時要同時更新根目錄 `workspace:` 清單和 CI。
