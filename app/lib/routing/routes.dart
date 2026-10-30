/// Route paths, shared by the router and the pages that navigate.
abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const items = '/items';
  static String item(String id) => '$items/$id';
  static const ledger = '/ledger';
  static const reports = '/reports';

  /// Under home: opened from its header on phones, from the rail otherwise.
  static const settings = '/home/settings';
}
