/// Brand identity. This is the only place the app name and Android
/// application ID are written down.
///
/// `android/app/build.gradle.kts` reads both constants from this file with a
/// regex, so keep each one a single-quoted literal on its own line.
abstract final class Brand {
  /// Provisional name; trademark and store-name checks are still pending.
  static const appName = 'CashRotate';

  /// Provisional Android application ID. Cannot change after the first
  /// Play Store release.
  static const applicationId = 'app.cashrotate';
}
