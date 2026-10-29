import 'dart:convert';
import 'dart:io';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

/// Checks the library as shipped in the app (app/assets/presets/presets.json)
/// and exercises search against real data.
void main() {
  final raw = jsonDecode(
    File('../../app/assets/presets/presets.json').readAsStringSync(),
  ) as List<Object?>;
  final presets = [for (final p in raw) Preset.fromJson(p)];
  final search = PresetSearch(presets);
  final byId = {for (final p in presets) p.id: p};

  List<String> ids(String q, {String? region}) =>
      search.search(q, region: region).map((p) => p.id).toList();

  group('shipped library', () {
    test('size and composition match the plan', () {
      expect(presets.length, inInclusiveRange(200, 300));
      final templates = presets.where((p) => p.isTemplate).length;
      final tw = presets
          .where(
            (p) => p.regions.contains('TW') && !p.regions.contains('global'),
          )
          .length;
      final hk = presets
          .where(
            (p) => p.regions.contains('HK') && !p.regions.contains('global'),
          )
          .length;
      final global = presets
          .where((p) => !p.isTemplate && p.regions.contains('global'))
          .length;
      expect(templates, inInclusiveRange(25, 40));
      expect(tw, inInclusiveRange(30, 50));
      expect(hk, inInclusiveRange(30, 50));
      expect(
        global,
        inInclusiveRange(110, 130),
        reason: 'about 120 global services',
      );
    });

    test('ids are unique and sorted', () {
      final list = presets.map((p) => p.id).toList();
      expect(list.toSet(), hasLength(list.length));
      expect(list, [...list]..sort());
    });

    test('carries no prices', () {
      final text = File('../../app/assets/presets/presets.json')
          .readAsStringSync();
      expect(text, isNot(contains('"price')));
      expect(text, isNot(contains('"amount')));
    });

    test('templates have all three languages', () {
      for (final p in presets.where((p) => p.isTemplate)) {
        expect(p.name.zhHant, isNotNull, reason: p.id);
        expect(p.name.zhHans, isNotNull, reason: p.id);
      }
    });

    test('services priced in one currency say so', () {
      expect(byId['chatgpt']!.currency, Currency.usd);
      expect(byId['claude']!.currency, Currency.usd);
      expect(byId['pixiv-fanbox']!.currency, Currency.jpy);
      expect(
        byId['netflix']!.currency,
        isNull,
        reason: 'billed in local currency',
      );
    });

    test('Chinese names carry pinyin and zhuyin keys', () {
      expect(byId['iqiyi']!.search.initials, contains('aqy'));
      expect(byId['iqiyi']!.search.zhuyin, contains('ㄞㄑㄧ'));
      expect(
        byId['netease-cloud-music']!.search.pinyin,
        contains('wangyiyunyinyue'),
      );
    });
  });

  group('search', () {
    test('English names, prefixes and typos', () {
      expect(ids('netflix').first, 'netflix');
      expect(ids('Net').first, 'netflix');
      expect(ids('ntflx').first, 'netflix');
      expect(ids('ＮＥＴＦＬＩＸ').first, 'netflix', reason: 'full-width input');
    });

    test('Chinese names in either script and aliases', () {
      expect(ids('網飛').first, 'netflix');
      expect(ids('奈飞').first, 'netflix');
      expect(ids('愛奇藝').first, 'iqiyi');
      expect(ids('爱奇艺').first, 'iqiyi');
      expect(ids('台哥大').first, 'tw-taiwan-mobile');
      expect(ids('房租').first, 'template-rent');
    });

    test('pinyin, pinyin initials and zhuyin initials', () {
      expect(ids('aiqiyi').first, 'iqiyi');
      expect(ids('aqy').first, 'iqiyi');
      expect(ids('ㄞㄑㄧ').first, 'iqiyi');
      expect(ids('zhdx').first, 'tw-chunghwa-telecom');
      expect(ids('ㄓㄏㄉㄒ').first, 'tw-chunghwa-telecom');
      expect(ids('fangzu').first, 'template-rent');
    });

    test('domains and merchant names from statements', () {
      expect(ids('netflix.com').first, 'netflix');
      expect(ids('APPLE.COM/BILL ICLOUD').first, 'icloud-plus');
    });

    test('region filter hides local services elsewhere', () {
      expect(ids('中華電信', region: 'TW'), contains('tw-chunghwa-telecom'));
      expect(ids('中華電信', region: 'HK'), isNot(contains('tw-chunghwa-telecom')));
      expect(ids('csl', region: 'HK').first, 'hk-csl');
      expect(ids('Netflix', region: 'HK').first, 'netflix');
    });

    test('empty and nonsense queries', () {
      expect(ids(''), isEmpty);
      expect(ids('   '), isEmpty);
      expect(ids('zzzzqqqq'), isEmpty);
    });

    test('exactMatch recognises one brand or none', () {
      expect(search.exactMatch('Spotify')?.id, 'spotify');
      expect(search.exactMatch('网飞')?.id, 'netflix');
      expect(search.exactMatch('Netfli'), isNull);
    });
  });
}
