/// Turns Chinese text into the search keys stored with each preset.
///
/// Readings come from a table generated from Unicode's Unihan database
/// (`kMandarin`), plus phrase overrides for characters whose reading depends
/// on the word (行 in 銀行, 樂 in 音樂). Used only at build time.
class HanReadings {
  HanReadings(this._chars, this._phrases);

  /// Parses `char<TAB>pinyin` lines (tone marks allowed) and phrase lines
  /// `phrase<TAB>space separated pinyin`. `#` starts a comment.
  factory HanReadings.parse(String charTable, String phraseTable) {
    Map<String, String> read(String text) => {
      for (final line in text.split('\n'))
        if (line.trim().isNotEmpty && !line.startsWith('#'))
          line.split('\t')[0]: line.split('\t')[1].trim(),
    };
    return HanReadings(read(charTable), read(phraseTable));
  }

  final Map<String, String> _chars;
  final Map<String, String> _phrases;

  static bool isHan(int rune) =>
      (rune >= 0x4E00 && rune <= 0x9FFF) || (rune >= 0x3400 && rune <= 0x4DBF);

  static bool containsHan(String text) => text.runes.any(isHan);

  /// Toneless syllables for [text], one per Han character, with Latin words
  /// kept whole. Throws if a character has no known reading.
  List<String> syllables(String text) {
    final out = <String>[];
    final latin = StringBuffer();
    void flushLatin() {
      if (latin.isNotEmpty) out.add(latin.toString().toLowerCase());
      latin.clear();
    }

    final chars = text.runes.map(String.fromCharCode).toList();
    var i = 0;
    outer:
    while (i < chars.length) {
      if (isHan(chars[i].runes.first)) {
        flushLatin();
        for (var len = chars.length - i; len >= 2; len--) {
          final phrase = chars.sublist(i, i + len).join();
          if (_phrases[phrase] case final reading?) {
            out.addAll(reading.split(' ').map(stripTones));
            i += len;
            continue outer;
          }
        }
        final reading = _chars[chars[i]];
        if (reading == null) {
          throw StateError('No reading for "${chars[i]}" in "$text"');
        }
        out.add(stripTones(reading));
      } else if (RegExp('[A-Za-z0-9]').hasMatch(chars[i])) {
        latin.write(chars[i]);
      } else {
        flushLatin();
      }
      i++;
    }
    flushLatin();
    return out;
  }

  /// Full pinyin, pinyin initials and zhuyin initials for [text].
  ({String pinyin, String initials, String zhuyin}) keys(String text) {
    final s = syllables(text);
    return (
      pinyin: s.join(),
      initials: s.map((x) => x[0]).join(),
      zhuyin: s.map(zhuyinInitial).join(),
    );
  }

  static const _toneless = {
    'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a', //
    'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e',
    'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
    'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
    'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
    'ǖ': 'v', 'ǘ': 'v', 'ǚ': 'v', 'ǜ': 'v', 'ü': 'v',
    'ń': 'n', 'ň': 'n', 'ǹ': 'n', 'ḿ': 'm',
  };

  /// "lǜ" → "lv", "xíng" → "xing". ü is typed as v on pinyin keyboards.
  static String stripTones(String syllable) => [
    for (final ch in syllable.toLowerCase().runes.map(String.fromCharCode))
      _toneless[ch] ?? ch,
  ].join();

  static const _consonants = {
    'zh': 'ㄓ', 'ch': 'ㄔ', 'sh': 'ㄕ', //
    'b': 'ㄅ', 'p': 'ㄆ', 'm': 'ㄇ', 'f': 'ㄈ', 'd': 'ㄉ', 't': 'ㄊ',
    'n': 'ㄋ', 'l': 'ㄌ', 'g': 'ㄍ', 'k': 'ㄎ', 'h': 'ㄏ', 'j': 'ㄐ',
    'q': 'ㄑ', 'x': 'ㄒ', 'r': 'ㄖ', 'z': 'ㄗ', 'c': 'ㄘ', 's': 'ㄙ',
  };

  static const _vowelStarts = [
    ('ang', 'ㄤ'), ('an', 'ㄢ'), ('ai', 'ㄞ'), ('ao', 'ㄠ'), ('a', 'ㄚ'), //
    ('ou', 'ㄡ'), ('o', 'ㄛ'),
    ('eng', 'ㄥ'), ('en', 'ㄣ'), ('ei', 'ㄟ'), ('er', 'ㄦ'), ('e', 'ㄜ'),
  ];

  /// First zhuyin symbol a user types for a toneless pinyin syllable.
  /// Latin words (not syllables) keep their first letter.
  static String zhuyinInitial(String syllable) {
    for (final len in [2, 1]) {
      if (syllable.length >= len) {
        if (_consonants[syllable.substring(0, len)] case final z?) {
          if (len == 1 &&
              'zcs'.contains(syllable[0]) &&
              syllable.startsWith('h', 1)) {
            continue; // zh/ch/sh handled by the two-letter pass
          }
          return z;
        }
      }
    }
    if (syllable.startsWith('yu') || syllable.startsWith('yong')) return 'ㄩ';
    if (syllable.startsWith('y')) return 'ㄧ';
    if (syllable.startsWith('w')) return 'ㄨ';
    for (final (prefix, z) in _vowelStarts) {
      if (syllable.startsWith(prefix)) return z;
    }
    return syllable[0];
  }
}
