import 'package:meta/meta.dart';

import '../fx/exchange_rate.dart';
import '../money/money.dart';
import '../time/local_date.dart';
import 'charge_parser.dart';

/// A pending charge a notification might be about.
@immutable
class ChargeCandidate {
  const ChargeCandidate({
    required this.itemId,
    required this.names,
    required this.expected,
    required this.dueOn,
    this.occurrenceId,
    this.cardLast4,
    this.accountFeeBasisPoints = 0,
  });

  final String itemId;

  /// Item name, preset names and aliases, personal aliases.
  final List<String> names;
  final Money expected;
  final LocalDate dueOn;
  final String? occurrenceId;

  /// The item's payment method card, if known.
  final String? cardLast4;

  /// That card's markup for foreign charges (set fee or learned).
  final int accountFeeBasisPoints;
}

/// How sure a match is.
enum MatchConfidence {
  /// Record it as paid automatically (with undo).
  high,

  /// Ask the user ("pending" list).
  low,
}

@immutable
class ChargeMatch {
  const ChargeMatch(this.candidate, this.score, this.confidence);

  final ChargeCandidate candidate;

  /// 0–1: name, amount, date and card evidence combined.
  final double score;
  final MatchConfidence confidence;
}

/// Days around the due date a charge may land (banks post late, renewals
/// run early).
const matchWindowDays = 5;

/// Score at or above which a match is recorded without asking.
const autoMatchScore = 0.8;

/// Lowest score worth asking about.
const askMatchScore = 0.45;

/// Finds which pending charge [charge] (seen on [on]) settles, if any.
///
/// Evidence: the merchant matches a name (0.45), the amount matches what
/// was due (0.35, or 0.2 within 5% / within the card's markup for a
/// foreign charge), the date falls within [matchWindowDays] of the due date
/// (0.15), and the card's last four digits match (0.05; a different card
/// counts against). Without a name match the amount and date must both fit.
ChargeMatch? matchCharge(
  ParsedCharge charge,
  LocalDate on,
  List<ChargeCandidate> candidates, {
  FxConverter? fx,
}) {
  ChargeMatch? best;
  final merchant = charge.merchant == null
      ? null
      : normalizeMerchant(charge.merchant!);
  for (final c in candidates) {
    var score = 0.0;
    final named =
        merchant != null &&
        merchant.length >= 3 &&
        c.names.any((n) {
          final name = normalizeMerchant(n);
          return name.length >= 3 &&
              (merchant.contains(name) || name.contains(merchant));
        });
    if (named) score += 0.45;

    final amountFit = _amountFit(charge.amount, c, fx);
    score += amountFit;

    final days = c.dueOn.daysUntil(on).abs();
    final inWindow = days <= matchWindowDays;
    if (inWindow) score += 0.15;

    if (charge.last4 != null && c.cardLast4 != null) {
      score += charge.last4 == c.cardLast4 ? 0.05 : -0.2;
    }
    if (!named && (amountFit < 0.35 || !inWindow)) continue;
    if (score < askMatchScore) continue;
    if (best == null || score > best.score) {
      best = ChargeMatch(
        c,
        score,
        score >= autoMatchScore ? MatchConfidence.high : MatchConfidence.low,
      );
    }
  }
  return best;
}

double _amountFit(Money charged, ChargeCandidate c, FxConverter? fx) {
  if (charged.currency == c.expected.currency) {
    if (charged == c.expected) return 0.35;
    final diff = (charged.minor - c.expected.minor).abs();
    return diff * 20 <= c.expected.minor ? 0.2 : 0; // within 5%
  }
  // Charged in the card's currency for a foreign price: compare with the
  // estimate, allowing the card's markup plus 3% for rate movement.
  final estimate = fx?.convert(c.expected, charged.currency)?.amount;
  if (estimate == null || estimate.minor == 0) return 0;
  final allowed =
      estimate.minor * (300 + c.accountFeeBasisPoints.abs()) ~/ 10000;
  final diff =
      charged.minor -
      estimate.minor * (10000 + c.accountFeeBasisPoints) ~/ 10000;
  return diff.abs() <= allowed ? 0.3 : 0;
}

/// A charge seen before that matched nothing, for new-subscription hints.
@immutable
class UnmatchedCharge {
  const UnmatchedCharge({
    required this.merchant,
    required this.amount,
    required this.on,
  });

  final String merchant;
  final Money amount;
  final LocalDate on;
}

/// Merchants charged about monthly (or weekly / yearly) that are not on the
/// list yet: at least two charges of the same merchant and currency, spaced
/// like a cycle. Returns the latest charge per such merchant.
List<UnmatchedCharge> recurringMerchants(List<UnmatchedCharge> seen) {
  final byMerchant = <String, List<UnmatchedCharge>>{};
  for (final c in seen) {
    byMerchant
        .putIfAbsent(
          '${normalizeMerchant(c.merchant)}|${c.amount.currency.code}',
          () => [],
        )
        .add(c);
  }
  final result = <UnmatchedCharge>[];
  for (final list in byMerchant.values) {
    if (list.length < 2) continue;
    list.sort((a, b) => a.on.compareTo(b.on));
    for (var i = 1; i < list.length; i++) {
      final gap = list[i - 1].on.daysUntil(list[i].on);
      final cyclic =
          (gap >= 6 && gap <= 8) ||
          (gap >= 26 && gap <= 35) ||
          (gap >= 355 && gap <= 375);
      if (cyclic) {
        result.add(list.last);
        break;
      }
    }
  }
  return result;
}
