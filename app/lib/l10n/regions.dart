import 'package:cashrotate_core/cashrotate_core.dart';

/// Regions offered when picking one; the user's own region is always added.
const commonRegions = [
  'TW',
  'HK',
  'MO',
  'CN',
  'JP',
  'KR',
  'SG',
  'MY',
  'US',
  'GB',
  'AU',
  'CA',
];

/// Region choices with [current] included even if it is not common.
List<String> regionChoices(String current) =>
    {...commonRegions, current}.toList();

/// "Taiwan (TW)" / "台灣 (TW)". Names come from the currency table so no
/// separate country list is kept; unknown regions show their code.
String regionName(String region, String language) {
  final info = CurrencyInfo.all
      .where((i) => i.regions.contains(region))
      .firstOrNull;
  final names = info?.countries ?? const <String>[];
  bool isChinese(String n) => n.runes.any((r) => r > 0x2E80);
  final zh = names.where(isChinese).toList();
  final en = names.where((n) => !isChinese(n)).firstOrNull;
  final name = switch (language) {
    'zh-Hant' => zh.firstOrNull,
    'zh-Hans' => zh.length > 1 ? zh.last : zh.firstOrNull,
    _ => en,
  };
  return name == null ? region : '$name ($region)';
}
