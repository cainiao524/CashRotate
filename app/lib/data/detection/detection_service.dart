import 'dart:convert';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../items/item_repository.dart';
import '../payments/payment_repository.dart';
import '../presets.dart';
import 'notice_platform.dart';

/// What became of a charge read from a notification.
enum DetectionStatus {
  /// Matched with high confidence and recorded as paid (can be undone).
  auto,

  /// Probably a charge of an item; waiting for the user.
  pending,

  /// Matched nothing; kept to spot new subscriptions.
  unmatched,

  /// The user assigned it to an item.
  assigned,

  /// The user dismissed it.
  ignored,

  /// An automatic match the user undid.
  undone,
}

/// One charge read from a notification. Keeps the parsed fields only, never
/// the notification text.
class Detection {
  Detection({
    required this.id,
    required this.at,
    required this.source,
    required this.amount,
    required this.status,
    this.merchant,
    this.last4,
    this.itemId,
    this.occurrenceId,
    this.transactionId,
    this.previousPaidUntil,
  });

  factory Detection.fromJson(Map<String, Object?> j) => Detection(
    id: j['id']! as String,
    at: DateTime.fromMillisecondsSinceEpoch(j['at']! as int),
    source: j['source']! as String,
    amount: Money(
      j['minor']! as int,
      Currency.tryParse(j['currency']! as String)!,
    ),
    status: DetectionStatus.values.byName(j['status']! as String),
    merchant: j['merchant'] as String?,
    last4: j['last4'] as String?,
    itemId: j['itemId'] as String?,
    occurrenceId: j['occurrenceId'] as String?,
    transactionId: j['transactionId'] as String?,
    previousPaidUntil: j['previousPaidUntil'] == null
        ? null
        : LocalDate.parse(j['previousPaidUntil']! as String),
  );

  final String id;
  final DateTime at;
  final String source;
  final Money amount;
  DetectionStatus status;
  final String? merchant;
  final String? last4;
  String? itemId;
  String? occurrenceId;
  String? transactionId;
  LocalDate? previousPaidUntil;

  LocalDate get on => LocalDate.fromDateTime(at);

  Map<String, Object?> toJson() => {
    'id': id,
    'at': at.millisecondsSinceEpoch,
    'source': source,
    'minor': amount.minor,
    'currency': amount.currency.code,
    'status': status.name,
    'merchant': merchant,
    'last4': last4,
    'itemId': itemId,
    'occurrenceId': occurrenceId,
    'transactionId': transactionId,
    'previousPaidUntil': previousPaidUntil?.toString(),
  };
}

/// Detection settings for this device: on/off and the apps to read.
class DetectionSettings {
  const DetectionSettings({this.enabled = false, this.packages = const []});

  final bool enabled;
  final List<String> packages;
}

/// Turns notices into payment records (ADR 0010): parses them on the phone,
/// matches them to pending charges, records confident matches as paid,
/// queues the rest, and remembers unmatched merchants to suggest new
/// subscriptions. All of it stays on this device (not synced).
class DetectionService {
  DetectionService(
    this._db,
    this._items,
    this._payments,
    this._platform, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final ItemRepository _items;
  final PaymentRepository _payments;
  final NoticePlatform _platform;
  final Uuid _uuid;

  static const _settingsKey = 'detection_settings';
  static const _listKey = 'detections';
  static const keep = 300;

  // --- stored state --------------------------------------------------------

  Future<String?> _meta(String key) async => (await (_db.select(
    _db.meta,
  )..where((m) => m.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _setMeta(String key, String value) => _db
      .into(_db.meta)
      .insertOnConflictUpdate(MetaCompanion.insert(key: key, value: value));

  Stream<String?> _watchMeta(String key) => (_db.select(
    _db.meta,
  )..where((m) => m.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  static DetectionSettings _parseSettings(String? raw) {
    if (raw == null) return const DetectionSettings();
    final j = jsonDecode(raw) as Map<String, Object?>;
    return DetectionSettings(
      enabled: j['enabled'] == true,
      packages: [...(j['packages'] as List? ?? const []).cast<String>()],
    );
  }

  Stream<DetectionSettings> watchSettings() =>
      _watchMeta(_settingsKey).map(_parseSettings);

  Future<DetectionSettings> settings() async =>
      _parseSettings(await _meta(_settingsKey));

  Future<void> setSettings(DetectionSettings s) async {
    await _setMeta(
      _settingsKey,
      jsonEncode({'enabled': s.enabled, 'packages': s.packages}),
    );
    await _platform.setConfig(enabled: s.enabled, packages: s.packages);
  }

  static List<Detection> _parseList(String? raw) => raw == null
      ? []
      : [
          for (final d in jsonDecode(raw) as List)
            Detection.fromJson((d as Map).cast<String, Object?>()),
        ];

  Stream<List<Detection>> watch() => _watchMeta(_listKey).map(_parseList);
  Future<List<Detection>> list() async => _parseList(await _meta(_listKey));

  Future<void> _save(List<Detection> list) => _setMeta(
    _listKey,
    jsonEncode([for (final d in list.take(keep)) d.toJson()]),
  );

  // --- processing ----------------------------------------------------------

  /// Reads waiting notices and shared text, and handles each. Returns the
  /// new detections.
  Future<List<Detection>> processWaiting({
    required String region,
    required Currency main,
    required FxConverter fx,
    required PresetLibrary? presets,
  }) async {
    final notices = [
      ...await _platform.takeNotices(),
      if (await _platform.takeSharedText() case final text?)
        Notice(source: Notice.shared, text: text, postedAt: DateTime.now()),
    ];
    final created = <Detection>[];
    for (final n in notices) {
      final d = await process(
        n,
        region: region,
        main: main,
        fx: fx,
        presets: presets,
      );
      if (d != null) created.add(d);
    }
    return created;
  }

  /// Handles one notice. Null when it is not a charge (or a repeat).
  Future<Detection?> process(
    Notice notice, {
    required String region,
    required Currency main,
    required FxConverter fx,
    required PresetLibrary? presets,
  }) async {
    final parsed = parseCharge(notice.text, region: region);
    if (parsed == null) return null;
    final existing = await list();
    // The same notification posted again (an update): once is enough.
    final repeat = existing.any(
      (d) =>
          d.source == notice.source &&
          d.amount == parsed.amount &&
          d.merchant == parsed.merchant &&
          d.at.difference(notice.postedAt).abs() < const Duration(minutes: 10),
    );
    if (repeat) return null;

    final on = LocalDate.fromDateTime(notice.postedAt);
    final accounts = await _db.select(_db.accounts).get();
    final candidates = await _candidates(on, accounts, presets);
    final match = matchCharge(parsed, on, candidates.keys.toList(), fx: fx);

    final detection = Detection(
      id: _uuid.v7(),
      at: notice.postedAt,
      source: notice.source,
      amount: parsed.amount,
      merchant: parsed.merchant,
      last4: parsed.last4,
      status: switch (match?.confidence) {
        MatchConfidence.high => DetectionStatus.auto,
        MatchConfidence.low => DetectionStatus.pending,
        null => DetectionStatus.unmatched,
      },
      itemId: match?.candidate.itemId,
      occurrenceId: match?.candidate.occurrenceId,
    );
    if (match?.confidence == MatchConfidence.high) {
      await _record(
        detection,
        match!.candidate.itemId,
        candidates[match.candidate],
        accounts,
        main,
        fx,
      );
    }
    await _save([detection, ...existing]);
    return detection;
  }

  /// Pending charges near [on] (value: the charge), plus irregular bills
  /// (value: null), which match by name alone.
  Future<Map<ChargeCandidate, OccurrenceRow?>> _candidates(
    LocalDate on,
    List<AccountRow> accounts,
    PresetLibrary? presets,
  ) async {
    final items = await _items.watchAll().first;
    final due = await _items
        .watchDue(on.addDays(-40), on.addDays(matchWindowDays))
        .first;
    final byId = {for (final v in items) v.row.id: v};
    final result = <ChargeCandidate, OccurrenceRow?>{};
    for (final o in due) {
      if (o.state != OccurrenceState.pending) continue;
      final v = byId[o.itemId];
      if (v == null ||
          v.row.status != ItemStatus.active ||
          v.row.needsDetails) {
        continue;
      }
      final preset = presets?.byId[v.row.presetId];
      final account = accounts
          .where((a) => a.id == v.row.accountId)
          .firstOrNull;
      final markup = account == null
          ? 0
          : await _payments.learnedMarkup(account.id) ??
                account.fxFeeBasisPoints ??
                0;
      result[ChargeCandidate(
            itemId: v.row.id,
            names: [v.row.name, ...?preset?.name.all, ...?preset?.aliases],
            expected: Money(o.expectedMinor, o.currency),
            dueOn: o.dueOn,
            occurrenceId: o.id,
            cardLast4: account?.cardLast4,
            accountFeeBasisPoints: markup,
          )] =
          o;
    }
    for (final v in items) {
      if (!v.irregular || v.row.status != ItemStatus.active) continue;
      final preset = presets?.byId[v.row.presetId];
      result[ChargeCandidate(
            itemId: v.row.id,
            names: [v.row.name, ...?preset?.name.all, ...?preset?.aliases],
            expected: v.schedule.prices.stablePrice,
            dueOn: on,
            anyAmount: true,
          )] =
          null;
    }
    return result;
  }

  Future<void> _record(
    Detection d,
    String itemId,
    OccurrenceRow? occurrence,
    List<AccountRow> accounts,
    Currency main,
    FxConverter fx,
  ) async {
    final view = await _items.view(itemId);
    d.previousPaidUntil = view.schedule.paidUntil;
    final byCard = d.last4 == null
        ? null
        : accounts.where((a) => a.cardLast4 == d.last4).firstOrNull;
    // An irregular bill expects whatever was charged.
    final expected = occurrence == null
        ? d.amount
        : Money(occurrence.expectedMinor, occurrence.currency);
    d.transactionId = await _payments.record(
      itemId: itemId,
      occurrenceId: occurrence?.id,
      expected: expected,
      paid: d.amount,
      paidOn: d.on,
      main: main,
      accountId: byCard?.id ?? view.row.accountId,
      marketRate: d.amount.currency == expected.currency
          ? null
          : fx.rate(expected.currency, d.amount.currency)?.rate,
      note: 'notification',
    );
    d.itemId = itemId;
    d.occurrenceId = occurrence?.id;
  }

  Future<void> _update(
    String id,
    Future<void> Function(Detection d) change,
  ) async {
    final all = await list();
    final d = all.where((x) => x.id == id).firstOrNull;
    if (d == null) return;
    await change(d);
    await _save(all);
  }

  /// Undoes an automatic match: removes the payment, the charge is due again.
  Future<void> undo(String id) => _update(id, (d) async {
    if (d.status != DetectionStatus.auto) return;
    if (d.transactionId case final tx?) await _payments.delete(tx);
    if (d.occurrenceId case final occ?) {
      await _items.reopen(occ, d.previousPaidUntil);
    }
    d.status = DetectionStatus.undone;
  });

  /// Records a pending (or unmatched) charge as a payment of [itemId]'s
  /// next charge.
  Future<void> assign(
    String id,
    String itemId, {
    required Currency main,
    required FxConverter fx,
  }) => _update(id, (d) async {
    final view = await _items.view(itemId);
    final next = view.nextDue;
    if (next == null && !view.irregular) return;
    final accounts = await _db.select(_db.accounts).get();
    await _record(d, itemId, view.irregular ? null : next, accounts, main, fx);
    d.status = DetectionStatus.assigned;
  });

  Future<void> ignore(String id) =>
      _update(id, (d) async => d.status = DetectionStatus.ignored);

  /// Unmatched merchants that charge on a cycle: candidates to add.
  List<UnmatchedCharge> suggestions(List<Detection> list) =>
      recurringMerchants([
        for (final d in list)
          if (d.status == DetectionStatus.unmatched && d.merchant != null)
            UnmatchedCharge(merchant: d.merchant!, amount: d.amount, on: d.on),
      ]);
}
