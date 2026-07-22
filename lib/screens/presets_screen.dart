import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';

class PresetsScreen extends StatelessWidget {
  const PresetsScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    bool isExpense = true;
    String category = Store.instance.categoriesFor(true).first.name;
    String walletId = Store.instance.wallets.first.id;
    final c = AppC.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(
      builder: (context, setD) => AlertDialog(
        backgroundColor: c.card,
        title: Text('New quick-add', style: TextStyle(color: c.text)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: true, label: Text('Expense')),
              ButtonSegment(value: false, label: Text('Income'))],
            selected: {isExpense},
            onSelectionChanged: (v) => setD(() { isExpense = v.first; category = Store.instance.categoriesFor(isExpense).first.name; })),
          const SizedBox(height: 12),
          TextField(controller: labelCtrl, style: TextStyle(color: c.text),
            decoration: const InputDecoration(hintText: 'Label (e.g. Tea, Bus)')),
          const SizedBox(height: 10),
          TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            style: TextStyle(color: c.text), decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Amount')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: category, isExpanded: true,
            dropdownColor: c.card, style: TextStyle(color: c.text),
            items: Store.instance.categoriesFor(isExpense).map((cat) =>
              DropdownMenuItem(value: cat.name, child: Text(cat.name))).toList(),
            onChanged: (v) => setD(() => category = v ?? category),
            decoration: const InputDecoration(labelText: 'Category')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: walletId, isExpanded: true,
            dropdownColor: c.card, style: TextStyle(color: c.text),
            items: Store.instance.wallets.map((w) =>
              DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
            onChanged: (v) => setD(() => walletId = v ?? walletId),
            decoration: const InputDecoration(labelText: 'Wallet')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    ));
    if (ok == true) {
      final a = double.tryParse(amountCtrl.text.trim());
      if (labelCtrl.text.trim().isNotEmpty && a != null && a > 0) {
        await Store.instance.addPreset(Preset(id: DateTime.now().microsecondsSinceEpoch.toString(),
          label: labelCtrl.text.trim(), amount: a, isExpense: isExpense, category: category, walletId: walletId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Quick-Add Presets')),
      floatingActionButton: FloatingActionButton(backgroundColor: kGreen, foregroundColor: Colors.white,
        onPressed: () => _add(context), child: const Icon(Icons.add)),
      body: ListenableBuilder(listenable: Store.instance, builder: (context, _) {
        final ps = Store.instance.presets;
        if (ps.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bolt, size: 56, color: c.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No quick-add presets', style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 4),
            Text('Create one-tap buttons for common spends', textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
          ])));
        }
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: ps.length, itemBuilder: (context, i) {
          final p = ps[i];
          final cat = Store.instance.categoryDef(p.category, p.isExpense);
          return Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: cat.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(cat.icon, color: cat.colour, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.label, style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
                Text('${p.category} · ${Store.instance.walletById(p.walletId).name}', style: TextStyle(color: c.muted, fontSize: 12)),
              ])),
              Text('${p.isExpense ? '-' : '+'}${money(p.amount)}',
                style: TextStyle(fontWeight: FontWeight.w700, color: p.isExpense ? kRed : kGreen)),
              IconButton(icon: Icon(Icons.delete_outline, color: c.muted),
                onPressed: () => Store.instance.removePreset(p.id)),
            ]),
          );
        });
      }),
    );
  }
}
