import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';

class UdhaarScreen extends StatelessWidget {
  const UdhaarScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final personCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool iLent = true;
    final c = AppC.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(
      builder: (context, setD) => AlertDialog(
        backgroundColor: c.card,
        title: Text('New udhaar', style: TextStyle(color: c.text)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: true, label: Text('They owe me')),
              ButtonSegment(value: false, label: Text('I owe'))],
            selected: {iLent}, onSelectionChanged: (v) => setD(() => iLent = v.first)),
          const SizedBox(height: 12),
          TextField(controller: personCtrl, style: TextStyle(color: c.text),
            decoration: const InputDecoration(hintText: 'Person name')),
          const SizedBox(height: 10),
          TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            style: TextStyle(color: c.text), decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Amount')),
          const SizedBox(height: 10),
          TextField(controller: noteCtrl, style: TextStyle(color: c.text),
            decoration: const InputDecoration(hintText: 'Note (optional)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    ));
    if (ok == true) {
      final a = double.tryParse(amountCtrl.text.trim());
      if (personCtrl.text.trim().isNotEmpty && a != null && a > 0) {
        await Store.instance.addDebt(Debt(id: DateTime.now().microsecondsSinceEpoch.toString(),
          person: personCtrl.text.trim(), amount: a, iLent: iLent, note: noteCtrl.text.trim(),
          timestamp: DateTime.now().millisecondsSinceEpoch));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Udhaar')),
      floatingActionButton: FloatingActionButton(backgroundColor: kGreen, foregroundColor: Colors.white,
        onPressed: () => _add(context), child: const Icon(Icons.add)),
      body: ListenableBuilder(listenable: Store.instance, builder: (context, _) {
        final s = Store.instance;
        final active = s.debts.where((d) => !d.settled).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final settled = s.debts.where((d) => d.settled).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            _summary(c, 'They owe me', money(s.theyOweMe), kGreen),
            const SizedBox(width: 12),
            _summary(c, 'I owe', money(s.iOwe), kRed),
          ]),
          const SizedBox(height: 18),
          if (active.isEmpty && settled.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Column(children: [
              Icon(Icons.handshake_outlined, size: 56, color: c.muted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('No udhaar recorded', style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
              const SizedBox(height: 4),
              Text('Track money you lent or borrowed', style: TextStyle(color: c.muted)),
            ]))),
          ...active.map((d) => _row(context, d, c)),
          if (settled.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('SETTLED', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 8),
            ...settled.map((d) => _row(context, d, c)),
          ],
        ]);
      }),
    );
  }

  Widget _summary(AppC c, String label, String value, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
    ])));

  Widget _row(BuildContext context, Debt d, AppC c) {
    final color = d.iLent ? kGreen : kRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Text(d.person.isNotEmpty ? d.person[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.person, style: TextStyle(fontWeight: FontWeight.w600, color: c.text,
            decoration: d.settled ? TextDecoration.lineThrough : null)),
          Text(d.iLent ? 'Owes you${d.note.isEmpty ? '' : ' · ${d.note}'}' : 'You owe${d.note.isEmpty ? '' : ' · ${d.note}'}',
            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12)),
        ])),
        Text(money(d.amount), style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        IconButton(
          icon: Icon(d.settled ? Icons.undo : Icons.check_circle_outline, color: c.muted),
          tooltip: d.settled ? 'Mark unsettled' : 'Mark settled',
          onPressed: () => Store.instance.toggleSettled(d.id)),
        IconButton(icon: Icon(Icons.delete_outline, color: c.muted),
          onPressed: () => Store.instance.removeDebt(d.id)),
      ]),
    );
  }
}
