import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../l10n.dart';
import '../add_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _query = '';
  int _filter = 0; // 0 all, 1 income, 2 expense
  int _sort = 0;   // 0 newest, 1 oldest, 2 highest, 3 lowest

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (context, _) {
        var txns = Store.instance.all;
        if (_filter == 1) txns = txns.where((t) => !t.isExpense).toList();
        if (_filter == 2) txns = txns.where((t) => t.isExpense).toList();
        if (_query.isNotEmpty) {
          final q = _query.toLowerCase();
          txns = txns.where((t) =>
              t.category.toLowerCase().contains(q) || t.note.toLowerCase().contains(q)).toList();
        }
        if (_sort == 1) txns.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (_sort == 2) txns.sort((a, b) => b.amount.compareTo(a.amount));
        if (_sort == 3) txns.sort((a, b) => a.amount.compareTo(b.amount));
        return Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 8, 6),
            child: Row(children: [
              Text(L.t('history'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text)),
              const Spacer(),
              PopupMenuButton<int>(
                icon: Icon(Icons.sort, color: c.text),
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 0, child: Text('Newest first')),
                  PopupMenuItem(value: 1, child: Text('Oldest first')),
                  PopupMenuItem(value: 2, child: Text('Highest amount')),
                  PopupMenuItem(value: 3, child: Text('Lowest amount')),
                ]),
            ])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: c.text),
              decoration: InputDecoration(
                hintText: L.t('search'), prefixIcon: Icon(Icons.search, color: c.muted),
                filled: true, fillColor: c.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0)))),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _chip(L.t('all'), 0, c), _chip(L.t('income'), 1, c), _chip(L.t('expense'), 2, c),
          ]),
          const SizedBox(height: 6),
          Expanded(child: txns.isEmpty
            ? Center(child: Text('No transactions found', style: TextStyle(color: c.muted)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 90),
                itemCount: txns.length,
                itemBuilder: (context, i) => _tile(context, txns[i], c))),
        ]);
      },
    );
  }

  Widget _chip(String label, int val, AppC c) {
    final sel = _filter == val;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(onTap: () => setState(() => _filter = val),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(color: sel ? kGreen : c.card, borderRadius: BorderRadius.circular(999)),
          child: Text(label, style: TextStyle(color: sel ? Colors.white : c.muted,
              fontWeight: sel ? FontWeight.w600 : FontWeight.w400)))));
  }

  Widget _tile(BuildContext context, Txn t, AppC c) {
    final cat = Store.instance.categoryDef(t.category, t.isExpense);
    final w = Store.instance.walletById(t.walletId);
    return Dismissible(
      key: ValueKey(t.id), direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, color: kRed,
        padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) => Store.instance.remove(t.id),
      child: GestureDetector(
        onTap: () => showAddSheet(context, edit: t),
        child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: cat.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(cat.icon, color: cat.colour, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.category, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: c.text)),
            Text('${w.name} · ${t.note.isEmpty ? dayLabel(t.date) : t.note}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${t.isExpense ? '-' : '+'}${money(t.amount)}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: t.isExpense ? kRed : kGreen)),
            Text(dayLabel(t.date), style: TextStyle(color: c.muted, fontSize: 11)),
          ]),
        ]),
      ),
      ),
    );
  }
}
