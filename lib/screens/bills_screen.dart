import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../notifications.dart';
import '../pickers.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  int _daysUntil(int dueDay) {
    final now = DateTime.now();
    final d = dueDay.clamp(1, 28);
    var due = DateTime(now.year, now.month, d);
    if (due.isBefore(DateTime(now.year, now.month, now.day))) {
      due = DateTime(now.year, now.month + 1, d);
    }
    return due.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Future<void> _add(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    int day = 1; String icon = 'bills'; int color = kColors[4]; bool remind = true;
    final c = AppC.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(
      builder: (context, setD) => AlertDialog(
        backgroundColor: c.card,
        title: Text('New bill / subscription', style: TextStyle(color: c.text)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: nameCtrl, style: TextStyle(color: c.text),
            decoration: const InputDecoration(hintText: 'Name (e.g. Netflix, Rent)')),
          const SizedBox(height: 10),
          TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            style: TextStyle(color: c.text), decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Amount')),
          const SizedBox(height: 12),
          Text('Due day of month: $day', style: TextStyle(color: c.text)),
          Slider(value: day.toDouble(), min: 1, max: 28, divisions: 27, activeColor: kGreen,
            label: '$day', onChanged: (v) => setD(() => day = v.round())),
          SwitchListTile(contentPadding: EdgeInsets.zero, activeThumbColor: kGreen,
            title: Text('Remind me', style: TextStyle(color: c.text)),
            value: remind, onChanged: (v) => setD(() => remind = v)),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text('Icon', style: TextStyle(color: c.muted))),
          const SizedBox(height: 8),
          IconPickerRow(selected: icon, onPick: (v) => setD(() => icon = v)),
          const SizedBox(height: 14),
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
    if (ok == true) {
      final a = double.tryParse(amountCtrl.text.trim());
      if (nameCtrl.text.trim().isNotEmpty && a != null && a > 0) {
        final bill = Bill(id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: nameCtrl.text.trim(), amount: a, dueDay: day, iconKey: icon, color: color, remind: remind);
        await Store.instance.addBill(bill);
        if (remind) {
          await Notifs.requestPermission();
          await Notifs.scheduleBill(bill.notifId, bill.dueDay, bill.name, money(bill.amount));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bills & Subscriptions')),
      floatingActionButton: FloatingActionButton(backgroundColor: kGreen, foregroundColor: Colors.white,
        onPressed: () => _add(context), child: const Icon(Icons.add)),
      body: ListenableBuilder(listenable: Store.instance, builder: (context, _) {
        final bills = Store.instance.bills.toList()..sort((a, b) => _daysUntil(a.dueDay).compareTo(_daysUntil(b.dueDay)));
        if (bills.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.notifications_none, size: 56, color: c.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No bills or subscriptions', style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 4),
            Text('Add rent, Netflix, gym… and get reminded', textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
          ])));
        }
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: bills.length, itemBuilder: (context, i) {
          final b = bills[i];
          final days = _daysUntil(b.dueDay);
          final soon = days <= 3;
          return Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(color: b.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(b.icon, color: b.colour, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(b.name, style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
                  if (b.remind) Padding(padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.notifications_active, size: 14, color: c.muted)),
                ]),
                Text(days == 0 ? 'Due today' : 'Due in $days day${days == 1 ? '' : 's'} (day ${b.dueDay})',
                  style: TextStyle(color: soon ? kRed : c.muted, fontSize: 12, fontWeight: soon ? FontWeight.w600 : FontWeight.w400)),
              ])),
              Text(money(b.amount), style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
              IconButton(icon: Icon(Icons.delete_outline, color: c.muted), onPressed: () {
                Notifs.cancelId(b.notifId);
                Store.instance.removeBill(b.id);
              }),
            ]),
          );
        });
      }),
    );
  }
}
