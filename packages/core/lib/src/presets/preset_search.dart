import 'preset.dart';

/// Folds text for matching: lowercase, full-width ASCII to half-width,
/// spaces and punctuation removed. CJK, kana and zhuyin are kept.
String normalizeForSearch(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    var r = rune;
    if (r >= 0xFF01 && r <= 0xFF5E) r -= 0xFEE0; // full-width ASCII
    if (r == 0x3000) continue; // ideographic space
    final ch = String.fromCharCode(r);
    if (_skip.hasMatch(ch)) continue;
    out.write(ch.toLowerCase());
  }
  return out.toString();
}

final _skip = RegExp(
  r'''[\s\-_.,:;!?'"()\[\]{}/\\|+&*#@~`^%$=<>·・、，。．！？：；（）【】「」『』《》〈〉]''',
);

/// A search hit and why it matched, for ranking.
typedef PresetHit = ({Preset preset, int score});

/// Local fuzzy search over the preset library: English and Chinese names,
/// aliases, full pinyin, pinyin initials and zhuyin initials.
class PresetSearch {
  PresetSearch(Iterable<Preset> presets)
    : _entries = [for (final p in presets) _Entry(p)];

  final List<_Entry> _entries;

  /// Presets matching [query], best first. Empty queries match nothing.
  /// Pass [region] to leave out presets that are not offered there.
  List<Preset> search(String query, {String? region, int limit = 50}) {
    final q = normalizeForSearch(query);
    if (q.isEmpty) return const [];
    final hits = <PresetHit>[];
    for (final e in _entries) {
      if (region != null && !e.preset.availableIn(region)) continue;
      final score = e.score(q);
      if (score > 0) hits.add((preset: e.preset, score: score));
    }
    hits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      // Equal scores: the shorter name is closer to what was typed.
      final byLength = a.preset.name.en.length.compareTo(
        b.preset.name.en.length,
      );
      return byLength != 0
          ? byLength
          : a.preset.name.en.compareTo(b.preset.name.en);
    });
    return [for (final h in hits.take(limit)) h.preset];
  }

  /// The preset whose name or alias equals [text] after normalisation, if
  /// exactly one does. Used to recognise brands in imported lists.
  Preset? exactMatch(String text) {
    final q = normalizeForSearch(text);
    if (q.isEmpty) return null;
    final matches = _entries.where((e) => e.texts.contains(q)).toList();
    return matches.length == 1 ? matches.single.preset : null;
  }
}

class _Entry {
  _Entry(this.preset)
    : texts = {
        for (final t in [...preset.name.all, ...preset.aliases, preset.id])
          normalizeForSearch(t),
      }..remove(''),
      pinyin = {for (final t in preset.search.pinyin) normalizeForSearch(t)},
      initials = {
        for (final t in [...preset.search.initials, ...preset.search.zhuyin])
          normalizeForSearch(t),
      };

  final Preset preset;
  final Set<String> texts;
  final Set<String> pinyin;
  final Set<String> initials;

  int score(String q) {
    var best = 0;
    void take(int s) {
      if (s > best) best = s;
    }

    for (final t in texts) {
      if (t == q) {
        take(100);
      } else if (t.startsWith(q)) {
        take(80);
      } else if (t.contains(q)) {
        take(60);
      } else if (q.length >= 3 && _isSubsequence(q, t)) {
        take(25);
      }
    }
    for (final t in pinyin) {
      if (t == q) {
        take(90);
      } else if (t.startsWith(q)) {
        take(70);
      } else if (q.length >= 2 && t.contains(q)) {
        take(45);
      }
    }
    for (final t in initials) {
      if (t == q) {
        take(85);
      } else if (q.length >= 2 && t.startsWith(q)) {
        take(65);
      } else if (q.length >= 2 && t.contains(q)) {
        take(40);
      }
    }
    return best;
  }

  /// Every character of [q] appears in [t] in order: "nflx" ⊂ "netflix".
  static bool _isSubsequence(String q, String t) {
    var i = 0;
    for (final ch in t.runes) {
      if (i < q.runes.length && ch == q.runes.elementAt(i)) i++;
    }
    return i == q.runes.length;
  }
}
