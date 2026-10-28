# 0003 本機資料庫：drift + SQLite3MultipleCiphers + Keystore 金鑰

- 狀態：已採用（2026-10-28）
- 決策者：專案擁有者（M1 開始時選定 SQLite3MultipleCiphers）

## 背景

CLAUDE.md 要求本機資料庫用 SQLite 加密（例如 drift 搭配 SQLCipher），金鑰存在 Keystore，選定前要確認套件仍在維護。

2026-10 查證：
- `sqlcipher_flutter_libs` 和 `sqlite3_flutter_libs` 都已標示停止維護（0.7.0+eol、0.6.0+eol，2026-02）。
- `sqlite3` 3.x（3.8.0，2026-10-23，MIT）改用 Dart build hooks 打包 SQLite。透過 `hooks.user_defines.sqlite3.source` 可以切換成上游 SQLite、SQLite3MultipleCiphers 或 SQLCipher。
- 預先編譯的檔案在 GitHub Actions 上建置，有 SLSA level 3 來源證明，下載後會比對 pub.dev 原始碼裡記錄的 sha256。

## 決定

| 項目 | 選擇 |
| --- | --- |
| ORM | `drift` 2.35（MIT，持續維護） |
| SQLite 版本 | `source: sqlite3mc`（SQLite3MultipleCiphers，MIT），寫在 workspace 根目錄的 `pubspec.yaml` |
| 加密演算法 | ChaCha20-Poly1305（`PRAGMA cipher = 'chacha20'`），有認證，能偵測竄改 |
| 金鑰 | 32 位元組隨機值（`SecureRandom`），以 `PRAGMA hexkey` 傳入 |
| 金鑰保管 | 用 Android Keystore 裡不可匯出的 AES-256-GCM 金鑰加密後，存在 `noBackupFilesDir/database.key` |
| 備份 | `allowBackup="false"`；`data_extraction_rules.xml` 排除雲端備份和裝置間轉移的所有資料 |

不選 SQLCipher 社群版的理由：它在 Android 上要一起打包 OpenSSL，APK 較大，也要多追蹤 OpenSSL 的安全更新；而且套件作者註明它的 SQLite 版本可能比較舊。之後如果有需要，SQLite3MultipleCiphers 也能切換成與 SQLCipher 4 相容的格式。

### 開啟流程
1. Dart 透過 `app.cashrotate/keystore` 通道呼叫 `databaseKey`。
2. Kotlin 端的 `DatabaseKeyStore` 讀取或建立金鑰，Keystore 操作放在背景執行緒。
3. `openEncryptedDatabase()` 依序設定 cipher、key，再立刻查詢一次 `sqlite_master`。金鑰錯誤會在這一步就失敗，不會拖到第一筆查詢。
4. 開啟失敗時，App 顯示「無法開啟你的資料」和「重試」按鈕，不會直接當掉。

## 影響

- 換裝置或重裝 App 後，舊的資料庫檔無法解開，這是刻意的設計。搬資料要用 M5 的 WebDAV 加密同步或 App 自己的備份。
- SQLite3MultipleCiphers 對 hex 金鑰仍會執行它預設的金鑰衍生（PBKDF2-SHA256），開啟時多花幾十毫秒。由於金鑰本身就是高熵隨機值，之後如果在低階手機上量到明顯延遲，可以把迭代次數調低。
- 已有測試驗證：載入的確實是 SQLite3MultipleCiphers、磁碟上的檔案看不到明文、錯誤金鑰和一般 SQLite 都打不開、外鍵約束有生效。
