import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../pickers.dart';

// ============================ Wallets ============================
class ManageWalletsScreen extends StatelessWidget {
  const ManageWalletsScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final nameCtrl = TextEditingController();
    String icon = 'wallet';
    int color = kColors[10];
    final c = AppC.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(
      builder: (context, setD) => AlertDialog(
        backgroundColor: c.card,
        title: Text('New wallet', style: TextStyle(color: c.text)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, style: TextStyle(color: c.text),
            decoration: const InputDecoration(hintText: 'Wallet name')),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: Text('Icon', style: TextStyle(color: c.muted))),
          const SizedBox(height: 8),
          IconPickerRow(selected: icon, onPick: (v) => setD(() => icon = v)),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: Text('Colour', style: TextStyle(color: c.muted))),
          const SizedBox(height: 8),
          ColorPickerRow(selected: color, onPick: (v) => setD(() => color = v)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    ));
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await Store.instance.addWallet(Wallet(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: nameCtrl.text.trim(), iconKey: icon, color: color));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Wallets')),
      floatingActionButton: FloatingActionButton(backgroundColor: kGreen, foregroundColor: Colors.white,
        onPressed: () => _add(context), child: const Icon(Icons.add)),
      body: ListenableBuilder(listenable: Store.instance, builder: (context, _) {
        final ws = Store.instance.wallets;
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: ws.length,
          itemBuilder: (context, i) {
            final w = ws[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: w.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(w.icon, color: w.colour, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w.name, style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
                  Text(money(Store.instance.walletBalance(w.id)), style: TextStyle(color: c.muted, fontSize: 12)),
                ])),
                if (ws.length > 1)
                  IconButton(icon: Icon(Icons.delete_outline, color: c.muted),
                    onPressed: () => Store.instance.removeWallet(w.id)),
              ]),
            );
          });
      }),
    );
  }
}

// ============================ Categories ============================
class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final nameCtrl = TextEditingController();
    bool isExpense = true;
    String icon = 'other';
    int color = kColors[0];
    final c = AppC.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(
      builder: (context, setD) => AlertDialog(
        backgroundColor: c.card,
        title: Text('New category', style: TextStyle(color: c.text)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, style: TextStyle(color: c.text),
            decoration: const InputDecoration(hintText: 'Category name')),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: true, label: Text('Expense')),
              ButtonSegment(value: false, label: Text('Income'))],
            selected: {isExpense}, onSelectionChanged: (v) => setD(() => isExpense = v.first)),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: Text('Icon', style: TextStyle(color: c.muted))),
          const SizedBox(height: 8),
          IconPickerRow(selected: icon, onPick: (v) => setD(() => icon = v)),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: Text('Colour', style: TextStyle(color: c.muted))),
          const SizedBox(height: 8),
          ColorPickerRow(selected: color, onPick: (v) => setD(() => color = v)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    ));
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await Store.instance.addCategory(CatDef(nameCtrl.text.trim(), icon, color, isExpense));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(backgroundColor: kGreen, foregroundColor: Colors.white,
        onPressed: () => _add(context), child: const Icon(Icons.add)),
      body: ListenableBuilder(listenable: Store.instance, builder: (context, _) {
        final s = Store.instance;
        final exp = s.categoriesFor(true);
        final inc = s.categoriesFor(false);
        Widget row(CatDef cat, bool custom) => Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: cat.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(cat.icon, color: cat.colour, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Text(cat.name, style: TextStyle(color: c.text))),
            if (custom)
              IconButton(icon: Icon(Icons.delete_outline, color: c.muted),
                onPressed: () => s.removeCategory(cat.name, cat.isExpense))
            else
              Text('default', style: TextStyle(color: c.muted, fontSize: 11)),
          ]),
        );
        final customExp = s.categoriesFor(true).where((cat) =>
            !defaultExpenseCats.any((d) => d.name == cat.name)).toList();
        final customInc = s.categoriesFor(false).where((cat) =>
            !defaultIncomeCats.any((d) => d.name == cat.name)).toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          Text('EXPENSE', style: TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          ...exp.map((cat) => row(cat, customExp.contains(cat))),
          const SizedBox(height: 16),
          Text('INCOME', style: TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          ...inc.map((cat) => row(cat, customInc.contains(cat))),
        ]);
      }),
    );
  }
}

// ============================ Recurring ============================
class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool isExpense = true;
    String category = Store.instance.categoriesFor(true).first.name;
    String walletId = Store.instance.wallets.first.id;
    int day = 1;
    final c = AppC.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(
      builder: (context, setD) => AlertDialog(
        backgroundColor: c.card,
        title: Text('New recurring', style: TextStyle(color: c.text)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: true, label: Text('Expense')),
              ButtonSegment(value: false, label: Text('Income'))],
            selected: {isExpense},
            onSelectionChanged: (v) => setD(() { isExpense = v.first; category = Store.instance.categoriesFor(isExpense).first.name; })),
          const SizedBox(height: 12),
          TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            style: TextStyle(color: c.text), decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Amount')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: category, isExpanded: true,
            dropdownColor: c.card, style: TextStyle(color: c.text),
            items: Store.instance.categoriesFor(isExpense).map((cat) =>
              DropdownMenuItem(value: cat.name, child: Text(cat.name))).toList(),
            onChanged: (v) => setD(() => category = v ?? category),
            decoration: const InputDecoration(labelText: 'Category')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: walletId, isExpanded: true,
            dropdownColor: c.card, style: TextStyle(color: c.text),
            items: Store.instance.wallets.map((w) =>
              DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
            onChanged: (v) => setD(() => walletId = v ?? walletId),
            decoration: const InputDecoration(labelText: 'Wallet')),
          const SizedBox(height: 12),
          Text('Day of month: $day', style: TextStyle(color: c.text)),
          Slider(value: day.toDouble(), min: 1, max: 28, divisions: 27, activeColor: kGreen,
            label: '$day', onChanged: (v) => setD(() => day = v.round())),
          TextField(controller: noteCtrl, style: TextStyle(color: c.text),
            decoration: const InputDecoration(hintText: 'Note (e.g. Rent)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    ));
    if (ok == true) {
      final amt = double.tryParse(amountCtrl.text.trim());
      if (amt != null && amt > 0) {
        await Store.instance.addRecurring(Recurring(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          amount: amt, isExpense: isExpense, category: category, walletId: walletId,
          note: noteCtrl.text.trim(), dayOfMonth: day));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring')),
      floatingActionButton: FloatingActionButton(backgroundColor: kGreen, foregroundColor: Colors.white,
        onPressed: () => _add(context), child: const Icon(Icons.add)),
      body: ListenableBuilder(listenable: Store.instance, builder: (context, _) {
        final rs = Store.instance.recurring;
        if (rs.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.repeat, size: 52, color: c.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No recurring transactions', style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 4),
            Text('Add rent, salary, subscriptions…', style: TextStyle(color: c.muted), textAlign: TextAlign.center),
          ])));
        }
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: rs.length, itemBuilder: (context, i) {
          final r = rs[i];
          final cat = Store.instance.categoryDef(r.category, r.isExpense);
          return Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: cat.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(cat.icon, color: cat.colour, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${r.category}${r.note.isEmpty ? '' : ' · ${r.note}'}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
                Text('Every month on day ${r.dayOfMonth}', style: TextStyle(color: c.muted, fontSize: 12)),
              ])),
              Text('${r.isExpense ? '-' : '+'}${money(r.amount)}',
                style: TextStyle(fontWeight: FontWeight.w700, color: r.isExpense ? kRed : kGreen)),
              IconButton(icon: Icon(Icons.delete_outline, color: c.muted),
                onPressed: () => Store.instance.removeRecurring(r.id)),
            ]),
          );
        });
      }),
    );
  }
}
