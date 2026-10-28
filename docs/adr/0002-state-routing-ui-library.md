# 0002 狀態管理、路由與 Material 函式庫

- 狀態：已採用（2026-10-28）
- 決策者：專案擁有者確認計畫決策 D2

## 決定

| 用途 | 套件 | 版本（採用時） | 維護 / 授權 |
| --- | --- | --- | --- |
| 狀態管理 | `flutter_riverpod` | 3.4.3 | dash-overflow.net，2026-09 仍有發布；MIT |
| 路由 | `go_router` | 18.1.1 | flutter.dev，2026-10 發布；BSD-3 |
| Material 元件 | `material_ui` | 1.8.0 | flutter.dev，2026-10 發布；BSD-3 |
| 格式化 | `intl` | 0.20.3 | dart.dev；BSD-3 |

### Riverpod 3（不用程式碼產生）
Repository、引擎、匯率服務都不依賴 BuildContext，測試時可以用 override 換掉。非同步資料（資料庫 stream、匯率）用 `AsyncValue`，正好對應每個元件都要有的載入、錯誤、空狀態。不用 `riverpod_generator`，少一層 build_runner。

### go_router
- `StatefulShellRoute.indexedStack`：五個主分頁各自保留狀態，切換分頁、旋轉、摺疊時，捲動位置與表單內容都不會遺失。
- `restorationScopeId`：App 被系統回收後可以還原到原本的頁面。
- 之後通知點擊進詳情，用深連結 `/items/:id`。
- 項目詳情：雙欄視窗用 `NoTransitionPage` 在列表旁顯示，單欄視窗推入新頁。

### material_ui（取代 `package:flutter/material.dart`）
Flutter 3.47 把 Material 移出框架，改成官方套件 `material_ui`，`go_router` 18 也已經改用它。如果混用兩種 import，會出現兩套 `ThemeData`，主題會失效。因此：
- 所有程式一律 `import 'package:material_ui/material_ui.dart'`。
- 本地化代理使用 `material_ui` 的 `GlobalMaterialLocalizations.delegates`。gen-l10n 產生的檔案仍會引用 `flutter_localizations`，所以保留這個依賴，但不使用它產生的 `localizationsDelegates`。
- 加入新的第三方 UI 套件前，先確認它用哪一套 Material；若用舊的，就用 `MaterialUiCompatibilityBridge` 銜接。

## 考慮過的替代方案
- Bloc：事件與狀態分離比較嚴謹，但樣板程式碼多，而這個 App 的狀態大多只是「資料庫查詢結果」。
- auto_route：功能相近，但需要程式碼產生，而且不是官方維護。
