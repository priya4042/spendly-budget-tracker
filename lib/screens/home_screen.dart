import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../l10n.dart';
import '../add_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (context, _) {
        final s = Store.instance;
        final m = s.selectedMonth;
        final txns = s.transactionsForMonth(m);
        return CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _header(context, c)),
          SliverToBoxAdapter(child: _monthBar(context, c, s)),
          SliverToBoxAdapter(child: _balanceCard(s, m)),
          SliverToBoxAdapter(child: _wallets(s, c)),
          SliverToBoxAdapter(child: _todayCard(s, c)),
          if (s.presets.isNotEmpty) SliverToBoxAdapter(child: _quickAdd(context, s, c)),
          if (s.insight != null) SliverToBoxAdapter(child: _insightCard(s.insight!, c)),
          if (s.budgets.isNotEmpty) SliverToBoxAdapter(child: _budgetSummary(s, m, c)),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              Text(L.t('thisMonth'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
              const Spacer(),
              Text('${txns.length} ${L.t('entries')}', style: TextStyle(color: c.muted, fontSize: 12)),
            ]))),
          if (txns.isEmpty)
            SliverToBoxAdapter(child: _empty(c))
          else
            SliverList.builder(itemCount: txns.length,
              itemBuilder: (context, i) => _tile(context, txns[i], c)),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ]);
      },
    );
  }

  Widget _header(BuildContext context, AppC c) {
    final streak = Store.instance.streak;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
      child: Row(children: [
        const Text('Spendly', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kGreen)),
        const SizedBox(width: 10),
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFFFA726).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
            child: Text('🔥 $streak day${streak == 1 ? '' : 's'}',
              style: const TextStyle(color: Color(0xFFF08C00), fontWeight: FontWeight.w700, fontSize: 12))),
        const Spacer(),
        IconButton(icon: Icon(Icons.settings_outlined, color: c.text),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      ]));
  }

  Widget _insightCard(String text, AppC c) => Container(
    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kGreen.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kGreen.withValues(alpha: 0.3))),
    child: Row(children: [
      const Icon(Icons.lightbulb_outline, color: kGreen, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w500))),
    ]));

  Widget _monthBar(BuildContext context, AppC c, Store s) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(onPressed: s.prevMonth, icon: Icon(Icons.chevron_left, color: c.text)),
      Text(monthLabel(s.selectedMonth), style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
      IconButton(onPressed: s.canGoNext ? s.nextMonth : null,
        icon: Icon(Icons.chevron_right, color: s.canGoNext ? c.text : c.muted.withValues(alpha: 0.3))),
    ]));

  Widget _todayCard(Store s, AppC c) {
    final safe = s.safeToSpendToday;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(L.t('today'), style: TextStyle(color: c.muted, fontSize: 12)),
          const SizedBox(height: 3),
          Text('-${money(s.todaySpent)}', style: const TextStyle(color: kRed, fontSize: 18, fontWeight: FontWeight.w800)),
        ])),
        if (safe != null) ...[
          Container(width: 1, height: 34, color: c.muted.withValues(alpha: 0.2)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L.t('safeToday'), style: TextStyle(color: c.muted, fontSize: 12)),
            const SizedBox(height: 3),
            Text(money(safe < 0 ? 0 : safe),
              style: TextStyle(color: safe < 0 ? kRed : kGreen, fontSize: 18, fontWeight: FontWeight.w800)),
          ])),
        ],
      ]),
    );
  }

  Widget _quickAdd(BuildContext context, Store s, AppC c) => Container(
    margin: const EdgeInsets.only(top: 16), height: 42,
    child: ListView.separated(scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: s.presets.length, separatorBuilder: (_, i) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final p = s.presets[i];
        return ActionChip(
          avatar: Icon(p.isExpense ? Icons.remove : Icons.add, size: 16, color: p.isExpense ? kRed : kGreen),
          label: Text('${p.label} ${money(p.amount)}'),
          onPressed: () async {
            await s.applyPreset(p);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added ${p.label}'), duration: const Duration(seconds: 1)));
            }
          },
        );
      }),
  );

  Widget _balanceCard(Store s, DateTime m) => Container(
    margin: const EdgeInsets.fromLTRB(20, 4, 20, 0), padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF12B886), Color(0xFF0C8F6B)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: kGreen.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(L.t('totalBalance'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
      const SizedBox(height: 6),
      Text(money(s.totalBalance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      Row(children: [
        _pill(Icons.arrow_downward, L.t('income'), money(s.monthIncome(m))),
        const SizedBox(width: 12),
        _pill(Icons.arrow_upward, L.t('expense'), money(s.monthExpense(m))),
      ]),
    ]));

  Widget _pill(IconData icon, String label, String value) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
        child: Icon(icon, size: 15, color: Colors.white)),
      const SizedBox(width: 9),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    ])));

  Widget _wallets(Store s, AppC c) => Container(
    height: 74, margin: const EdgeInsets.only(top: 16),
    child: ListView.separated(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: s.wallets.length, separatorBuilder: (_, i) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        final w = s.wallets[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: w.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(w.icon, color: w.colour, size: 18)),
            const SizedBox(width: 10),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.name, style: TextStyle(fontSize: 12, color: c.muted)),
              Text(money(s.walletBalance(w.id)), style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
            ]),
          ]),
        );
      },
    ));

  Widget _budgetSummary(Store s, DateTime m, AppC c) {
    // show the category budget closest to being exceeded
    String? worst; double worstPct = -1;
    s.budgets.forEach((cat, limit) {
      final pct = limit == 0 ? 0 : s.categorySpent(cat, m) / limit;
      if (pct > worstPct) { worstPct = pct.toDouble(); worst = cat; }
    });
    if (worst == null) return const SizedBox.shrink();
    final limit = s.budgetFor(worst!);
    final spent = s.categorySpent(worst!, m);
    final pct = (limit == 0 ? 0.0 : (spent / limit)).clamp(0.0, 1.0);
    final over = spent > limit;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(over ? Icons.warning_amber : Icons.savings_outlined, size: 18, color: over ? kRed : kGreen),
          const SizedBox(width: 8),
          Text('Budget: ${worst!}', style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
          const Spacer(),
          Text('${money(spent)} / ${money(limit)}', style: TextStyle(fontSize: 12, color: c.muted)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: pct, minHeight: 8,
            backgroundColor: c.field, color: over ? kRed : kGreen)),
      ]),
    );
  }

  Widget _tile(BuildContext context, Txn t, AppC c) {
    final cat = Store.instance.categoryDef(t.category, t.isExpense);
    return Dismissible(
      key: ValueKey(t.id), direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, color: kRed,
        padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) => Store.instance.remove(t.id),
      child: GestureDetector(
        onTap: () => showAddSheet(context, edit: t),
        child: Container(
        margin: const EdgeInsets.fromLTRB(20, 5, 20, 5), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: cat.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(cat.icon, color: cat.colour, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.category, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: c.text)),
            Text(t.note.isEmpty ? dayLabel(t.date) : '${t.note} · ${dayLabel(t.date)}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12)),
          ])),
          Text('${t.isExpense ? '-' : '+'}${money(t.amount)}',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: t.isExpense ? kRed : kGreen)),
        ]),
      ),
      ),
    );
  }

  Widget _empty(AppC c) => Padding(padding: const EdgeInsets.only(top: 50), child: Center(child: Column(children: [
    Icon(Icons.receipt_long_outlined, size: 56, color: c.muted.withValues(alpha: 0.5)),
    const SizedBox(height: 12),
    Text(L.t('noTxnMonth'), style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
    const SizedBox(height: 4),
    Text('Tap + to add one', style: TextStyle(color: c.muted)),
  ])));
}
