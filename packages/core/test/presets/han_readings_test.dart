import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

void main() {
  final readings = HanReadings.parse(
    '愛\tài\n奇\tqí\n藝\tyì\n音\tyīn\n樂\tlè\n綠\tlǜ\n中\tzhōng\n華\thuá\n月\tyuè\n',
    '音樂\tyīn yuè\n',
  );

  test('strips tones and writes ü as v', () {
    expect(HanReadings.stripTones('xíng'), 'xing');
    expect(HanReadings.stripTones('lǜ'), 'lv');
    expect(HanReadings.stripTones('Ài'), 'ai');
  });

  test('keys: full pinyin, pinyin initials, zhuyin initials', () {
    expect(readings.keys('愛奇藝'), (
      pinyin: 'aiqiyi',
      initials: 'aqy',
      zhuyin: 'ㄞㄑㄧ',
    ));
  });

  test('phrase overrides beat single-character readings', () {
    expect(readings.keys('音樂').pinyin, 'yinyue');
    expect(readings.keys('樂').pinyin, 'le');
  });

  test('Latin words stay whole between Chinese', () {
    expect(readings.syllables('中華 HiNet 月'), ['zhong', 'hua', 'hinet', 'yue']);
  });

  test('unknown characters are reported, not guessed', () {
    expect(() => readings.syllables('龘'), throwsStateError);
  });

  group('zhuyinInitial', () {
    const cases = {
      'zhong': 'ㄓ',
      'chi': 'ㄔ',
      'shi': 'ㄕ',
      'ri': 'ㄖ',
      'zi': 'ㄗ',
      'ci': 'ㄘ',
      'si': 'ㄙ', //
      'ba': 'ㄅ',
      'pa': 'ㄆ',
      'ma': 'ㄇ',
      'fa': 'ㄈ',
      'da': 'ㄉ',
      'ta': 'ㄊ',
      'na': 'ㄋ',
      'la': 'ㄌ',
      'ga': 'ㄍ', 'ka': 'ㄎ', 'ha': 'ㄏ', 'ji': 'ㄐ', 'qi': 'ㄑ', 'xi': 'ㄒ',
      'yi': 'ㄧ',
      'ya': 'ㄧ',
      'yao': 'ㄧ',
      'yu': 'ㄩ',
      'yue': 'ㄩ',
      'yuan': 'ㄩ',
      'yong': 'ㄩ',
      'wu': 'ㄨ',
      'wang': 'ㄨ',
      'a': 'ㄚ',
      'ai': 'ㄞ',
      'ao': 'ㄠ',
      'an': 'ㄢ',
      'ang': 'ㄤ',
      'o': 'ㄛ',
      'ou': 'ㄡ',
      'e': 'ㄜ',
      'ei': 'ㄟ',
      'en': 'ㄣ',
      'eng': 'ㄥ',
      'er': 'ㄦ',
    };
    for (final MapEntry(key: syllable, value: zhuyin) in cases.entries) {
      test(
        '$syllable → $zhuyin',
        () => expect(HanReadings.zhuyinInitial(syllable), zhuyin),
      );
    }
  });
}
