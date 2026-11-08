import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../data/settings/settings_repository.dart';

/// Built-in line icons a home tile can show instead of its initial. Generic
/// symbols only: no brand marks. Names are stored, so never rename one.
const tileIcons = <String, IconData>{
  'phone': Icons.smartphone_outlined,
  'wifi': Icons.wifi,
  'home': Icons.home_outlined,
  'building': Icons.apartment_outlined,
  'bolt': Icons.bolt_outlined,
  'water': Icons.water_drop_outlined,
  'fire': Icons.local_fire_department_outlined,
  'server': Icons.dns_outlined,
  'globe': Icons.language,
  'cloud': Icons.cloud_outlined,
  'code': Icons.code,
  'ai': Icons.auto_awesome_outlined,
  'tv': Icons.tv_outlined,
  'movie': Icons.movie_outlined,
  'music': Icons.music_note_outlined,
  'game': Icons.sports_esports_outlined,
  'book': Icons.menu_book_outlined,
  'school': Icons.school_outlined,
  'fitness': Icons.fitness_center_outlined,
  'health': Icons.health_and_safety_outlined,
  'shield': Icons.shield_outlined,
  'car': Icons.directions_car_outlined,
  'transit': Icons.train_outlined,
  'card': Icons.credit_card_outlined,
  'loan': Icons.account_balance_outlined,
  'savings': Icons.savings_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'family': Icons.family_restroom_outlined,
  'pet': Icons.pets_outlined,
  'receipt': Icons.receipt_long_outlined,
};

/// The first character of [name], upper-cased; "?" when blank.
String initialOf(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty
      ? '?'
      : String.fromCharCode(trimmed.runes.first).toUpperCase();
}

/// What an item's badge shows: the user's picture, else the chosen line
/// icon, else the user's own text or the initial; and the user's own colour
/// (`#RRGGBB`) if any.
({String text, IconData? icon, String? color, Uint8List? image}) badgeOf(
  String itemId,
  String name,
  UserSettings? settings,
) {
  final own = settings?.tileBadges[itemId];
  return (
    text: own?.text ?? initialOf(name),
    icon: tileIcons[settings?.tileIcons[itemId]],
    color: own?.color,
    image: settings?.tileImages[itemId],
  );
}

/// Colours offered for a badge: greys first (the app is monochrome), then
/// muted hues. Each takes black or white text, whichever reads better.
const badgeColors = [
  '#111111',
  '#5F6368',
  '#B0B0AC',
  '#E6E6E3',
  '#B91C1C',
  '#C2410C',
  '#B45309',
  '#4D7C0F',
  '#0F766E',
  '#1D4ED8',
  '#6D28D9',
  '#BE185D',
];
