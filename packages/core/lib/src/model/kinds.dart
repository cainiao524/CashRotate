/// The five kinds of fixed expense. Each brings its own fields and reminders.
enum ItemType {
  /// Streaming, cloud, software, gym …: plans, trials, cancel links.
  subscription,

  /// Phone, broadband, utilities, rent: amounts vary, contracts expire.
  bill,

  /// Credit cards, mortgages, instalments, family loans: counted periods.
  repayment,

  /// Insurance premiums, licence taxes, card annual fees, memberships.
  insuranceAndFees,

  /// Allowances to parents, regular investing, savings plans. Money leaves
  /// but is not spending, so reports keep it apart from consumption.
  transferOut,
}

enum AccountType {
  cash,
  bank,
  creditCard,
  eWallet,

  /// Transit cards, Steam Wallet, game points.
  storedValue,

  /// Balance only; holdings are not tracked.
  investment,

  /// Money lent to or borrowed from someone.
  loan,
}

/// Transactions are only ever one of these three.
enum TransactionType {
  expense,
  income,

  /// Between the user's own accounts (card payments, top-ups). Never counted
  /// as spending, so it is not counted twice.
  transfer,
}

enum TransactionStatus {
  /// Created automatically when a fixed expense falls due; the user confirms
  /// or corrects the amount.
  pending,
  confirmed,
}

enum CategoryKind { expense, income }
