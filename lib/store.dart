import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Central app state: transactions, wallets, categories, budgets, recurring,
/// settings and the currently-viewed month. Everything persists locally.
class Store extends ChangeNotifier {
  Store._();
  static final Store instance = Store._();

  final List<Txn> _txns = [];
  final List<Wallet> _wallets = [];
  final List<CatDef> _customCats = [];
  final Map<String, double> _budgets = {}; // category -> monthly limit
  final List<Recurring> _recurring = [];
  final List<Goal> _goals = [];
  final List<Debt> _debts = [];
  final List<Bill> _bills = [];
  final List<Preset> _presets = [];
  final List<Loan> _loans = [];

  // Settings
  bool darkMode = false;
  bool lockEnabled = false;
  String pin = '';
  bool reminderEnabled = false;
  int reminderHour = 20;
  int reminderMinute = 0;
  String currencySymbol = '₹';
  String lang = 'en'; // 'en' or 'hi'
  bool roundUpEnabled = false;
  int roundUpNearest = 10;
  double roundUpTotal = 0;

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool loaded = false;

  // ---------- Load / save ----------
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _readList(p.getString('txns_v1'), _txns, (j) => Txn.fromJson(j));
    _readList(p.getString('wallets_v1'), _wallets, (j) => Wallet.fromJson(j));
    _readList(p.getString('customcats_v1'), _customCats, (j) => CatDef.fromJson(j));
    _readList(p.getString('recurring_v1'), _recurring, (j) => Recurring.fromJson(j));
    _readList(p.getString('goals_v1'), _goals, (j) => Goal.fromJson(j));
    _readList(p.getString('debts_v1'), _debts, (j) => Debt.fromJson(j));
    _readList(p.getString('bills_v1'), _bills, (j) => Bill.fromJson(j));
    _readList(p.getString('presets_v1'), _presets, (j) => Preset.fromJson(j));
    _readList(p.getString('loans_v1'), _loans, (j) => Loan.fromJson(j));
    if (_wallets.isEmpty) _wallets.addAll(defaultWallets);

    final b = p.getString('budgets_v1');
    if (b != null && b.isNotEmpty) {
      try {
        (jsonDecode(b) as Map<String, dynamic>).forEach((k, v) => _budgets[k] = (v as num).toDouble());
      } catch (_) {}
    }
    final s = p.getString('settings_v1');
    if (s != null && s.isNotEmpty) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        darkMode = m['darkMode'] ?? false;
        lockEnabled = m['lockEnabled'] ?? false;
        pin = m['pin'] ?? '';
        reminderEnabled = m['reminderEnabled'] ?? false;
        reminderHour = m['reminderHour'] ?? 20;
        reminderMinute = m['reminderMinute'] ?? 0;
        currencySymbol = m['currencySymbol'] ?? '₹';
        lang = m['lang'] ?? 'en';
        roundUpEnabled = m['roundUpEnabled'] ?? false;
        roundUpNearest = m['roundUpNearest'] ?? 10;
        roundUpTotal = (m['roundUpTotal'] ?? 0).toDouble();
      } catch (_) {}
    }
    _applyRecurring();
    loaded = true;
    notifyListeners();
  }

  void _readList<T>(String? raw, List<T> target, T Function(Map<String, dynamic>) f) {
    target.clear();
    if (raw == null || raw.isEmpty) return;
    try {
      for (final e in (jsonDecode(raw) as List)) {
        target.add(f(e as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('txns_v1', jsonEncode(_txns.map((e) => e.toJson()).toList()));
    await p.setString('wallets_v1', jsonEncode(_wallets.map((e) => e.toJson()).toList()));
    await p.setString('customcats_v1', jsonEncode(_customCats.map((e) => e.toJson()).toList()));
    await p.setString('recurring_v1', jsonEncode(_recurring.map((e) => e.toJson()).toList()));
    await p.setString('goals_v1', jsonEncode(_goals.map((e) => e.toJson()).toList()));
    await p.setString('debts_v1', jsonEncode(_debts.map((e) => e.toJson()).toList()));
    await p.setString('bills_v1', jsonEncode(_bills.map((e) => e.toJson()).toList()));
    await p.setString('presets_v1', jsonEncode(_presets.map((e) => e.toJson()).toList()));
    await p.setString('loans_v1', jsonEncode(_loans.map((e) => e.toJson()).toList()));
    await p.setString('budgets_v1', jsonEncode(_budgets));
    await p.setString('settings_v1', jsonEncode({
      'darkMode': darkMode, 'lockEnabled': lockEnabled, 'pin': pin,
      'reminderEnabled': reminderEnabled, 'reminderHour': reminderHour, 'reminderMinute': reminderMinute,
      'currencySymbol': currencySymbol, 'lang': lang,
      'roundUpEnabled': roundUpEnabled, 'roundUpNearest': roundUpNearest, 'roundUpTotal': roundUpTotal,
    }));
  }

  // ---------- Transactions ----------
  List<Txn> get all {
    final l = List<Txn>.from(_txns);
    l.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return l;
  }

  List<Txn> transactionsForMonth(DateTime m) =>
      all.where((t) => t.date.year == m.year && t.date.month == m.month).toList();

  Future<void> add(Txn t) async {
    _txns.add(t);
    // Round-up savings: on each expense, save the "spare change" to the jar.
    if (roundUpEnabled && t.isExpense && roundUpNearest > 0) {
      final rounded = (t.amount / roundUpNearest).ceil() * roundUpNearest;
      final spare = rounded - t.amount;
      if (spare > 0) roundUpTotal += spare;
    }
    notifyListeners(); await _save();
  }
  Future<void> remove(String id) async { _txns.removeWhere((t) => t.id == id); notifyListeners(); await _save(); }
  Future<void> update(Txn t) async {
    final i = _txns.indexWhere((x) => x.id == t.id);
    if (i >= 0) { _txns[i] = t; } else { _txns.add(t); }
    notifyListeners(); await _save();
  }

  // ---------- Month navigation ----------
  void prevMonth() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    notifyListeners();
  }
  void nextMonth() {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    final next = DateTime(selectedMonth.year, selectedMonth.month + 1);
    if (!next.isAfter(now)) { selectedMonth = next; notifyListeners(); }
  }
  bool get canGoNext {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    return DateTime(selectedMonth.year, selectedMonth.month + 1).isBefore(now) ||
        DateTime(selectedMonth.year, selectedMonth.month + 1).isAtSameMomentAs(now);
  }

  bool _same(DateTime d, DateTime m) => d.year == m.year && d.month == m.month;

  // ---------- Computed ----------
  double get totalBalance =>
      _wallets.fold(0.0, (s, w) => s + w.openingBalance) +
      _txns.fold(0.0, (s, t) => s + (t.isExpense ? -t.amount : t.amount));

  double walletBalance(String id) {
    final opening = _wallets.where((w) => w.id == id).fold(0.0, (s, w) => s + w.openingBalance);
    return opening + _txns.where((t) => t.walletId == id)
        .fold(0.0, (s, t) => s + (t.isExpense ? -t.amount : t.amount));
  }

  /// Total expense recorded today.
  double get todaySpent {
    final now = DateTime.now();
    return _txns.where((t) => t.isExpense &&
        t.date.year == now.year && t.date.month == now.month && t.date.day == now.day)
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Rough "safe to spend today" = (total category budgets - spent this month) / days left.
  /// Returns null if no budgets are set.
  double? get safeToSpendToday {
    if (_budgets.isEmpty) return null;
    final now = DateTime.now();
    final totalBudget = _budgets.values.fold(0.0, (s, v) => s + v);
    final spent = monthExpense(DateTime(now.year, now.month));
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = (daysInMonth - now.day) + 1;
    final remaining = totalBudget - spent;
    if (daysLeft <= 0) return remaining;
    return remaining / daysLeft;
  }

  double monthIncome(DateTime m) => _txns.where((t) => !t.isExpense && _same(t.date, m)).fold(0.0, (s, t) => s + t.amount);
  double monthExpense(DateTime m) => _txns.where((t) => t.isExpense && _same(t.date, m)).fold(0.0, (s, t) => s + t.amount);

  List<MapEntry<String, double>> expenseByCategory(DateTime m) {
    final map = <String, double>{};
    for (final t in _txns) {
      if (t.isExpense && _same(t.date, m)) map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    final e = map.entries.toList();
    e.sort((a, b) => b.value.compareTo(a.value));
    return e;
  }

  double categorySpent(String category, DateTime m) => _txns
      .where((t) => t.isExpense && t.category == category && _same(t.date, m))
      .fold(0.0, (s, t) => s + t.amount);

  /// Last 6 months of total expense, oldest first: (DateTime month, total).
  List<MapEntry<DateTime, double>> last6MonthsExpense() {
    final now = DateTime.now();
    final out = <MapEntry<DateTime, double>>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      out.add(MapEntry(m, monthExpense(m)));
    }
    return out;
  }

  // ---------- Wallets ----------
  List<Wallet> get wallets => List.unmodifiable(_wallets);
  Wallet walletById(String id) =>
      _wallets.firstWhere((w) => w.id == id, orElse: () => _wallets.first);
  Future<void> addWallet(Wallet w) async { _wallets.add(w); notifyListeners(); await _save(); }
  Future<void> removeWallet(String id) async {
    if (_wallets.length <= 1) return;
    _wallets.removeWhere((w) => w.id == id);
    notifyListeners(); await _save();
  }
  Future<void> setOpeningBalance(String id, double value) async {
    final w = _wallets.firstWhere((w) => w.id == id, orElse: () => _wallets.first);
    w.openingBalance = value; notifyListeners(); await _save();
  }

  // ---------- Presets ----------
  List<Preset> get presets => List.unmodifiable(_presets);
  Future<void> addPreset(Preset p) async { _presets.add(p); notifyListeners(); await _save(); }
  Future<void> removePreset(String id) async { _presets.removeWhere((p) => p.id == id); notifyListeners(); await _save(); }
  /// Immediately record a transaction from a preset (dated now).
  Future<void> applyPreset(Preset p) async {
    await add(Txn(id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: p.amount, isExpense: p.isExpense, category: p.category, walletId: p.walletId,
      note: p.label, timestamp: DateTime.now().millisecondsSinceEpoch));
  }

  // ---------- Categories ----------
  List<CatDef> categoriesFor(bool isExpense) {
    final base = isExpense ? defaultExpenseCats : defaultIncomeCats;
    return [...base, ..._customCats.where((c) => c.isExpense == isExpense)];
  }
  CatDef categoryDef(String name, bool isExpense) => categoriesFor(isExpense)
      .firstWhere((c) => c.name == name, orElse: () => const CatDef('Other', 'other', 0xFF78909C, true));
  Future<void> addCategory(CatDef c) async { _customCats.add(c); notifyListeners(); await _save(); }
  Future<void> removeCategory(String name, bool isExpense) async {
    _customCats.removeWhere((c) => c.name == name && c.isExpense == isExpense);
    notifyListeners(); await _save();
  }

  // ---------- Budgets ----------
  Map<String, double> get budgets => Map.unmodifiable(_budgets);
  double budgetFor(String category) => _budgets[category] ?? 0;
  Future<void> setBudget(String category, double limit) async {
    if (limit <= 0) { _budgets.remove(category); } else { _budgets[category] = limit; }
    notifyListeners(); await _save();
  }

  // ---------- Recurring ----------
  List<Recurring> get recurring => List.unmodifiable(_recurring);
  Future<void> addRecurring(Recurring r) async { _recurring.add(r); notifyListeners(); await _save(); }
  Future<void> removeRecurring(String id) async { _recurring.removeWhere((r) => r.id == id); notifyListeners(); await _save(); }

  void _applyRecurring() {
    final now = DateTime.now();
    final key = '${now.year}-${now.month}';
    bool changed = false;
    for (final r in _recurring) {
      if (r.lastApplied == key) continue;
      final day = r.dayOfMonth.clamp(1, 28);
      // only apply once we've reached that day of the month
      if (now.day >= day) {
        _txns.add(Txn(
          id: 'rec_${r.id}_$key',
          amount: r.amount, isExpense: r.isExpense, category: r.category,
          walletId: r.walletId, note: r.note.isEmpty ? 'Recurring' : r.note,
          timestamp: DateTime(now.year, now.month, day, 9).millisecondsSinceEpoch,
        ));
        r.lastApplied = key;
        changed = true;
      }
    }
    if (changed) _save();
  }

  // ---------- Savings goals ----------
  List<Goal> get goals => List.unmodifiable(_goals);
  Future<void> addGoal(Goal g) async { _goals.add(g); notifyListeners(); await _save(); }
  Future<void> removeGoal(String id) async { _goals.removeWhere((g) => g.id == id); notifyListeners(); await _save(); }
  Future<void> contributeGoal(String id, double amount) async {
    final g = _goals.firstWhere((g) => g.id == id, orElse: () => _goals.first);
    g.saved = (g.saved + amount).clamp(0, g.target);
    notifyListeners(); await _save();
  }

  // ---------- Udhaar (debts) ----------
  List<Debt> get debts => List.unmodifiable(_debts);
  double get theyOweMe => _debts.where((d) => !d.settled && d.iLent).fold(0.0, (s, d) => s + d.amount);
  double get iOwe => _debts.where((d) => !d.settled && !d.iLent).fold(0.0, (s, d) => s + d.amount);
  Future<void> addDebt(Debt d) async { _debts.add(d); notifyListeners(); await _save(); }
  Future<void> removeDebt(String id) async { _debts.removeWhere((d) => d.id == id); notifyListeners(); await _save(); }
  Future<void> toggleSettled(String id) async {
    final d = _debts.firstWhere((d) => d.id == id);
    d.settled = !d.settled; notifyListeners(); await _save();
  }

  // ---------- Bills ----------
  List<Bill> get bills => List.unmodifiable(_bills);
  Future<void> addBill(Bill b) async { _bills.add(b); notifyListeners(); await _save(); }
  Future<void> removeBill(String id) async { _bills.removeWhere((b) => b.id == id); notifyListeners(); await _save(); }

  // ---------- Loans / EMI ----------
  List<Loan> get loans => List.unmodifiable(_loans);
  double get totalLoanRemaining => _loans.fold(0.0, (s, l) => s + l.remaining);
  Future<void> addLoan(Loan l) async { _loans.add(l); notifyListeners(); await _save(); }
  Future<void> removeLoan(String id) async { _loans.removeWhere((l) => l.id == id); notifyListeners(); await _save(); }
  Future<void> payEmi(String id) async {
    final l = _loans.firstWhere((l) => l.id == id);
    if (l.paidMonths < l.totalMonths) l.paidMonths++;
    notifyListeners(); await _save();
  }
  Future<void> undoEmi(String id) async {
    final l = _loans.firstWhere((l) => l.id == id);
    if (l.paidMonths > 0) l.paidMonths--;
    notifyListeners(); await _save();
  }

  // ---------- Round-up savings ----------
  Future<void> resetRoundUp() async { roundUpTotal = 0; notifyListeners(); await _save(); }
  /// Move the round-up jar into a savings goal.
  Future<void> moveRoundUpToGoal(String goalId) async {
    final amt = roundUpTotal;
    roundUpTotal = 0;
    await contributeGoal(goalId, amt); // saves + notifies
  }

  // ---------- Streak ----------
  /// Consecutive days (ending today or yesterday) with at least one transaction.
  int get streak {
    if (_txns.isEmpty) return 0;
    final days = _txns.map((t) {
      final d = t.date; return DateTime(d.year, d.month, d.day);
    }).toSet();
    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    int count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  // ---------- Insight ----------
  /// A short human insight comparing this month's spend to last month.
  String? get insight {
    final now = DateTime.now();
    final thisM = monthExpense(DateTime(now.year, now.month));
    final lastM = monthExpense(DateTime(now.year, now.month - 1));
    if (thisM == 0 && lastM == 0) return null;
    if (lastM == 0) return 'You have spent ${_fmt(thisM)} so far this month.';
    final diff = ((thisM - lastM) / lastM * 100).round();
    if (diff > 5) return 'You are spending $diff% more than last month. Watch your budget!';
    if (diff < -5) return 'Nice! You are spending ${diff.abs()}% less than last month.';
    return 'Your spending is about the same as last month.';
  }

  String _fmt(double v) => '₹${v.toStringAsFixed(0)}';

  // ---------- Settings ----------
  Future<void> saveSettings() async { notifyListeners(); await _save(); }

  // ---------- CSV export ----------
  String buildCsv() {
    String esc(String s) => '"${s.replaceAll('"', '""')}"';
    final rows = <String>['Date,Type,Category,Wallet,Amount,Note'];
    for (final t in all) {
      final d = t.date;
      rows.add([
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        t.isExpense ? 'Expense' : 'Income',
        esc(t.category),
        esc(walletById(t.walletId).name),
        t.amount.toStringAsFixed(2),
        esc(t.note),
      ].join(','));
    }
    return rows.join('\n');
  }

  // ---------- Full backup / restore (JSON) ----------
  String buildBackupJson() {
    return jsonEncode({
      'version': 4,
      'txns': _txns.map((e) => e.toJson()).toList(),
      'wallets': _wallets.map((e) => e.toJson()).toList(),
      'customCats': _customCats.map((e) => e.toJson()).toList(),
      'recurring': _recurring.map((e) => e.toJson()).toList(),
      'goals': _goals.map((e) => e.toJson()).toList(),
      'debts': _debts.map((e) => e.toJson()).toList(),
      'bills': _bills.map((e) => e.toJson()).toList(),
      'presets': _presets.map((e) => e.toJson()).toList(),
      'loans': _loans.map((e) => e.toJson()).toList(),
      'budgets': _budgets,
    });
  }

  /// Replace all data from a backup JSON string. Returns true on success.
  Future<bool> restoreBackupJson(String raw) async {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      void fill<T>(String key, List<T> target, T Function(Map<String, dynamic>) f) {
        target.clear();
        for (final e in (m[key] as List? ?? [])) {
          target.add(f(e as Map<String, dynamic>));
        }
      }
      fill('txns', _txns, (j) => Txn.fromJson(j));
      fill('wallets', _wallets, (j) => Wallet.fromJson(j));
      fill('customCats', _customCats, (j) => CatDef.fromJson(j));
      fill('recurring', _recurring, (j) => Recurring.fromJson(j));
      fill('goals', _goals, (j) => Goal.fromJson(j));
      fill('debts', _debts, (j) => Debt.fromJson(j));
      fill('bills', _bills, (j) => Bill.fromJson(j));
      fill('presets', _presets, (j) => Preset.fromJson(j));
      fill('loans', _loans, (j) => Loan.fromJson(j));
      if (_wallets.isEmpty) _wallets.addAll(defaultWallets);
      _budgets.clear();
      (m['budgets'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _budgets[k] = (v as num).toDouble());
      notifyListeners();
      await _save();
      return true;
    } catch (_) {
      return false;
    }
  }
}
