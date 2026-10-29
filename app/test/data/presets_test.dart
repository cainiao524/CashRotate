import 'package:cashrotate/data/presets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled preset library loads and searches', () async {
    final library = await PresetLibrary.load(rootBundle);
    expect(library.presets.length, inInclusiveRange(200, 300));
    expect(library.byId['netflix']!.name.resolve('zh-Hans'), '奈飞');
    expect(library.search.search('aqy').first.id, 'iqiyi');
  });

  test('availableIn lists local services first and templates last', () async {
    final library = await PresetLibrary.load(rootBundle);
    final hk = library.availableIn('HK');
    expect(hk.map((p) => p.id), contains('hk-csl'));
    expect(hk.map((p) => p.id), isNot(contains('tw-chunghwa-telecom')));
    final firstTemplate = hk.indexWhere((p) => p.isTemplate);
    expect(hk.skip(firstTemplate).every((p) => p.isTemplate), isTrue);
  });
}
