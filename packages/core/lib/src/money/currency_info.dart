import '../presets/preset.dart' show LocalizedText;
import 'currency.dart';

/// Display and search data for a [Currency].
final class CurrencyInfo {
  const CurrencyInfo._(
    this.currency,
    this.symbol,
    this.name,
    this.countries, {
    this.regions = const [],
  });

  final Currency currency;

  /// Unambiguous symbol to print: `NT$`, `US$`, `JP¥`, `CN¥`, `€`. When a
  /// currency's usual symbol is shared (Rs, K, F, сом …) this is the ISO code.
  final String symbol;
  final LocalizedText name;

  /// Country and territory names (all languages) for search.
  final List<String> countries;

  /// ISO 3166 regions that use it, for picking a default from the locale.
  final List<String> regions;

  /// Whether [symbol] is just the code, so formatting puts a space after it.
  bool get symbolIsCode => symbol == currency.code;

  static CurrencyInfo of(Currency c) => _byCode[c.code]!;

  /// Main currency for a region code; USD when the region is not covered.
  static Currency forRegion(String? region) {
    if (region == null) return Currency.usd;
    for (final info in all) {
      if (info.regions.contains(region.toUpperCase())) return info.currency;
    }
    return Currency.usd;
  }

  /// Search by code, names, countries or symbol. Results keep [all]'s order
  /// within each tier: code match, then prefix matches, then the rest.
  static List<CurrencyInfo> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    int tier(CurrencyInfo i) {
      final texts = [
        i.currency.code,
        ...i.name.all,
        ...i.countries,
        i.symbol,
      ].map((t) => t.toLowerCase());
      if (i.currency.code.toLowerCase() == q || i.symbol.toLowerCase() == q) {
        return 0;
      }
      if (texts.any((t) => t.startsWith(q))) return 1;
      if (texts.any((t) => t.contains(q))) return 2;
      return 3;
    }

    final scored = [
      for (final i in all)
        if (tier(i) < 3) (info: i, tier: tier(i)),
    ]..sort((a, b) => a.tier.compareTo(b.tier));
    return [for (final s in scored) s.info];
  }

  static const _euro = [
    'AT', 'BE', 'CY', 'DE', 'EE', 'ES', 'FI', 'FR', 'GR', 'HR', 'IE', 'IT', //
    'LT', 'LU', 'LV', 'MT', 'NL', 'PT', 'SI', 'SK',
  ];

  static const all = <CurrencyInfo>[
    CurrencyInfo._(
      Currency.twd,
      r'NT$',
      LocalizedText(en: 'New Taiwan dollar', zhHant: '新臺幣', zhHans: '新台币'),
      ['Taiwan', '台灣', '臺灣', '台湾'],
      regions: ['TW'],
    ),
    CurrencyInfo._(
      Currency.hkd,
      r'HK$',
      LocalizedText(en: 'Hong Kong dollar', zhHant: '港幣', zhHans: '港币'),
      ['Hong Kong', '香港'],
      regions: ['HK'],
    ),
    CurrencyInfo._(
      Currency.mop,
      r'MOP$',
      LocalizedText(en: 'Macanese pataca', zhHant: '澳門元', zhHans: '澳门元'),
      ['Macau', 'Macao', '澳門', '澳门'],
      regions: ['MO'],
    ),
    CurrencyInfo._(
      Currency.cny,
      'CN¥',
      LocalizedText(en: 'Chinese yuan', zhHant: '人民幣', zhHans: '人民币'),
      ['China', '中國', '中国', 'RMB'],
      regions: ['CN'],
    ),
    CurrencyInfo._(
      Currency.jpy,
      'JP¥',
      LocalizedText(en: 'Japanese yen', zhHant: '日圓', zhHans: '日元'),
      ['Japan', '日本'],
      regions: ['JP'],
    ),
    CurrencyInfo._(
      Currency.krw,
      '₩',
      LocalizedText(en: 'South Korean won', zhHant: '韓元', zhHans: '韩元'),
      ['South Korea', 'Korea', '韓國', '韩国'],
      regions: ['KR'],
    ),
    CurrencyInfo._(
      Currency.mnt,
      '₮',
      LocalizedText(en: 'Mongolian tögrög', zhHant: '蒙古圖格里克', zhHans: '蒙古图格里克'),
      ['Mongolia', '蒙古'],
      regions: ['MN'],
    ),
    CurrencyInfo._(
      Currency.sgd,
      r'S$',
      LocalizedText(en: 'Singapore dollar', zhHant: '新加坡元', zhHans: '新加坡元'),
      ['Singapore', '新加坡'],
      regions: ['SG'],
    ),
    CurrencyInfo._(
      Currency.myr,
      'RM',
      LocalizedText(
        en: 'Malaysian ringgit',
        zhHant: '馬來西亞令吉',
        zhHans: '马来西亚林吉特',
      ),
      ['Malaysia', '馬來西亞', '马来西亚'],
      regions: ['MY'],
    ),
    CurrencyInfo._(
      Currency.thb,
      '฿',
      LocalizedText(en: 'Thai baht', zhHant: '泰銖', zhHans: '泰铢'),
      ['Thailand', '泰國', '泰国'],
      regions: ['TH'],
    ),
    CurrencyInfo._(
      Currency.vnd,
      '₫',
      LocalizedText(en: 'Vietnamese đồng', zhHant: '越南盾', zhHans: '越南盾'),
      ['Vietnam', '越南'],
      regions: ['VN'],
    ),
    CurrencyInfo._(
      Currency.php,
      '₱',
      LocalizedText(en: 'Philippine peso', zhHant: '菲律賓披索', zhHans: '菲律宾比索'),
      ['Philippines', '菲律賓', '菲律宾'],
      regions: ['PH'],
    ),
    CurrencyInfo._(
      Currency.idr,
      'Rp',
      LocalizedText(en: 'Indonesian rupiah', zhHant: '印尼盾', zhHans: '印尼盾'),
      ['Indonesia', '印尼', '印度尼西亞', '印度尼西亚'],
      regions: ['ID'],
    ),
    CurrencyInfo._(
      Currency.bnd,
      r'B$',
      LocalizedText(en: 'Brunei dollar', zhHant: '汶萊元', zhHans: '文莱元'),
      ['Brunei', '汶萊', '文莱'],
      regions: ['BN'],
    ),
    CurrencyInfo._(
      Currency.khr,
      '៛',
      LocalizedText(en: 'Cambodian riel', zhHant: '柬埔寨瑞爾', zhHans: '柬埔寨瑞尔'),
      ['Cambodia', '柬埔寨'],
      regions: ['KH'],
    ),
    CurrencyInfo._(
      Currency.lak,
      '₭',
      LocalizedText(en: 'Lao kip', zhHant: '寮國基普', zhHans: '老挝基普'),
      ['Laos', '寮國', '老挝'],
      regions: ['LA'],
    ),
    CurrencyInfo._(
      Currency.mmk,
      'MMK',
      LocalizedText(en: 'Myanmar kyat', zhHant: '緬甸元', zhHans: '缅甸元'),
      ['Myanmar', 'Burma', '緬甸', '缅甸'],
      regions: ['MM'],
    ),
    CurrencyInfo._(
      Currency.inr,
      '₹',
      LocalizedText(en: 'Indian rupee', zhHant: '印度盧比', zhHans: '印度卢比'),
      ['India', '印度'],
      regions: ['IN'],
    ),
    CurrencyInfo._(
      Currency.pkr,
      'PKR',
      LocalizedText(en: 'Pakistani rupee', zhHant: '巴基斯坦盧比', zhHans: '巴基斯坦卢比'),
      ['Pakistan', '巴基斯坦'],
      regions: ['PK'],
    ),
    CurrencyInfo._(
      Currency.bdt,
      '৳',
      LocalizedText(en: 'Bangladeshi taka', zhHant: '孟加拉塔卡', zhHans: '孟加拉塔卡'),
      ['Bangladesh', '孟加拉'],
      regions: ['BD'],
    ),
    CurrencyInfo._(
      Currency.lkr,
      'LKR',
      LocalizedText(en: 'Sri Lankan rupee', zhHant: '斯里蘭卡盧比', zhHans: '斯里兰卡卢比'),
      ['Sri Lanka', '斯里蘭卡', '斯里兰卡'],
      regions: ['LK'],
    ),
    CurrencyInfo._(
      Currency.npr,
      'NPR',
      LocalizedText(en: 'Nepalese rupee', zhHant: '尼泊爾盧比', zhHans: '尼泊尔卢比'),
      ['Nepal', '尼泊爾', '尼泊尔'],
      regions: ['NP'],
    ),
    CurrencyInfo._(
      Currency.btn,
      'Nu.',
      LocalizedText(
        en: 'Bhutanese ngultrum',
        zhHant: '不丹努扎姆',
        zhHans: '不丹努尔特鲁姆',
      ),
      ['Bhutan', '不丹'],
      regions: ['BT'],
    ),
    CurrencyInfo._(
      Currency.mvr,
      'Rf',
      LocalizedText(
        en: 'Maldivian rufiyaa',
        zhHant: '馬爾地夫拉菲亞',
        zhHans: '马尔代夫拉菲亚',
      ),
      ['Maldives', '馬爾地夫', '马尔代夫'],
      regions: ['MV'],
    ),
    CurrencyInfo._(
      Currency.afn,
      '؋',
      LocalizedText(en: 'Afghan afghani', zhHant: '阿富汗尼', zhHans: '阿富汗尼'),
      ['Afghanistan', '阿富汗'],
      regions: ['AF'],
    ),
    CurrencyInfo._(
      Currency.aud,
      r'A$',
      LocalizedText(en: 'Australian dollar', zhHant: '澳幣', zhHans: '澳元'),
      ['Australia', '澳洲', '澳大利亚'],
      regions: ['AU'],
    ),
    CurrencyInfo._(
      Currency.nzd,
      r'NZ$',
      LocalizedText(en: 'New Zealand dollar', zhHant: '紐西蘭幣', zhHans: '新西兰元'),
      ['New Zealand', '紐西蘭', '新西兰'],
      regions: ['NZ'],
    ),
    CurrencyInfo._(
      Currency.fjd,
      r'FJ$',
      LocalizedText(en: 'Fijian dollar', zhHant: '斐濟元', zhHans: '斐济元'),
      ['Fiji', '斐濟', '斐济'],
      regions: ['FJ'],
    ),
    CurrencyInfo._(
      Currency.pgk,
      'PGK',
      LocalizedText(
        en: 'Papua New Guinean kina',
        zhHant: '巴布亞紐幾內亞基那',
        zhHans: '巴布亚新几内亚基那',
      ),
      ['Papua New Guinea', '巴布亞紐幾內亞', '巴布亚新几内亚'],
      regions: ['PG'],
    ),
    CurrencyInfo._(
      Currency.sbd,
      r'SI$',
      LocalizedText(
        en: 'Solomon Islands dollar',
        zhHant: '索羅門群島元',
        zhHans: '所罗门群岛元',
      ),
      ['Solomon Islands', '索羅門群島', '所罗门群岛'],
      regions: ['SB'],
    ),
    CurrencyInfo._(
      Currency.vuv,
      'VT',
      LocalizedText(en: 'Vanuatu vatu', zhHant: '萬那杜瓦圖', zhHans: '瓦努阿图瓦图'),
      ['Vanuatu', '萬那杜', '瓦努阿图'],
      regions: ['VU'],
    ),
    CurrencyInfo._(
      Currency.wst,
      r'WS$',
      LocalizedText(en: 'Samoan tālā', zhHant: '薩摩亞塔拉', zhHans: '萨摩亚塔拉'),
      ['Samoa', '薩摩亞', '萨摩亚'],
      regions: ['WS'],
    ),
    CurrencyInfo._(
      Currency.top,
      r'T$',
      LocalizedText(en: "Tongan pa'anga", zhHant: '東加潘加', zhHans: '汤加潘加'),
      ['Tonga', '東加', '汤加'],
      regions: ['TO'],
    ),
    CurrencyInfo._(
      Currency.xpf,
      'XPF',
      LocalizedText(en: 'CFP franc', zhHant: '太平洋法郎', zhHans: '太平洋法郎'),
      [
        'French Polynesia',
        'New Caledonia',
        '法屬玻里尼西亞',
        '新喀里多尼亞',
        '法属波利尼西亚',
        '新喀里多尼亚',
      ],
      regions: ['PF', 'NC', 'WF'],
    ),
    CurrencyInfo._(
      Currency.kzt,
      '₸',
      LocalizedText(
        en: 'Kazakhstani tenge',
        zhHant: '哈薩克堅戈',
        zhHans: '哈萨克斯坦坚戈',
      ),
      ['Kazakhstan', '哈薩克', '哈萨克斯坦'],
      regions: ['KZ'],
    ),
    CurrencyInfo._(
      Currency.uzs,
      'UZS',
      LocalizedText(
        en: 'Uzbekistani soʻm',
        zhHant: '烏茲別克蘇姆',
        zhHans: '乌兹别克斯坦苏姆',
      ),
      ['Uzbekistan', '烏茲別克', '乌兹别克斯坦'],
      regions: ['UZ'],
    ),
    CurrencyInfo._(
      Currency.kgs,
      'KGS',
      LocalizedText(
        en: 'Kyrgyzstani som',
        zhHant: '吉爾吉斯索姆',
        zhHans: '吉尔吉斯斯坦索姆',
      ),
      ['Kyrgyzstan', '吉爾吉斯', '吉尔吉斯斯坦'],
      regions: ['KG'],
    ),
    CurrencyInfo._(
      Currency.tjs,
      'TJS',
      LocalizedText(
        en: 'Tajikistani somoni',
        zhHant: '塔吉克索莫尼',
        zhHans: '塔吉克斯坦索莫尼',
      ),
      ['Tajikistan', '塔吉克', '塔吉克斯坦'],
      regions: ['TJ'],
    ),
    CurrencyInfo._(
      Currency.tmt,
      'TMT',
      LocalizedText(
        en: 'Turkmenistan manat',
        zhHant: '土庫曼馬納特',
        zhHans: '土库曼斯坦马纳特',
      ),
      ['Turkmenistan', '土庫曼', '土库曼斯坦'],
      regions: ['TM'],
    ),
    CurrencyInfo._(
      Currency.usd,
      r'US$',
      LocalizedText(en: 'US dollar', zhHant: '美元', zhHans: '美元'),
      ['United States', 'USA', '美國', '美国', '美金'],
      regions: ['US', 'EC', 'SV', 'PA', 'TL', 'PW', 'FM', 'MH'],
    ),
    CurrencyInfo._(
      Currency.eur,
      '€',
      LocalizedText(en: 'Euro', zhHant: '歐元', zhHans: '欧元'),
      ['Euro area', 'Europe', '歐洲', '欧洲'],
      regions: _euro,
    ),
  ];

  static final _byCode = {for (final i in all) i.currency.code: i};
}
