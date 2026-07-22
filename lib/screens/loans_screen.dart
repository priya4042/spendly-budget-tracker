import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../notifications.dart';
import '../pickers.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emiCtrl = TextEditingController();
    final monthsCtrl = TextEditingController();
    int day = 5; String icon = 'bank'; int color = kColors[12]; bool remind = true;
    final c = AppC.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(
      builder: (context, setD) => AlertDialog(
        backgroundColor: c.card,
        title: Text('New loan / EMI', style: TextStyle(color: c.text)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: nameCtrl, style: TextStyle(color: c.text),
            decoration: const InputDecoration(hintText: 'Name (e.g. Bike loan)')),
          const SizedBox(height: 10),
          TextField(controller: emiCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            style: TextStyle(color: c.text), decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Monthly EMI amount')),
          const SizedBox(height: 10),
          TextField(controller: monthsCtrl, keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: c.text), decoration: const InputDecoration(hintText: 'Total months (e.g. 24)')),
          const SizedBox(height: 12),
          Text('Due day of month: $day', style: TextStyle(color: c.text)),
          Slider(value: day.toDouble(), min: 1, max: 28, divisions: 27, activeColor: kGreen,
            label: '$day', onChanged: (v) => setD(() => day = v.round())),
          SwitchListTile(contentPadding: EdgeInsets.zero, activeThumbColor: kGreen,
            title: Text('Remind on due day', style: TextStyle(color: c.text)),
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
      final emi = double.tryParse(emiCtrl.text.trim());
      final months = int.tryParse(monthsCtrl.text.trim());
      if (nameCtrl.text.trim().isNotEmpty && emi != null && emi > 0 && months != null && months > 0) {
        final loan = Loan(id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: nameCtrl.text.trim(), emiAmount: emi, totalMonths: months, dueDay: day,
          iconKey: icon, color: color, remind: remind);
        await Store.instance.addLoan(loan);
        if (remind) {
          await Notifs.requestPermission();
          await Notifs.scheduleBill(loan.notifId, loan.dueDay, '${loan.name} EMI', money(loan.emiAmount));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Loans & EMIs')),
      floatingActionButton: FloatingActionButton(backgroundColor: kGreen, foregroundColor: Colors.white,
        onPressed: () => _add(context), child: const Icon(Icons.add)),
      body: ListenableBuilder(listenable: Store.instance, builder: (context, _) {
        final loans = Store.instance.loans;
        return ListView(padding: const EdgeInsets.all(16), children: [
          if (loans.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(18), margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)]),
                borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total remaining', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(money(Store.instance.totalLoanRemaining),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              ])),
          if (loans.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 60), child: Center(child: Column(children: [
              Icon(Icons.account_balance, size: 56, color: c.muted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('No loans or EMIs', style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
              const SizedBox(height: 4),
              Text('Track bike, phone or home loans', style: TextStyle(color: c.muted)),
            ])))
          else
            ...loans.map((l) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: l.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(l.icon, color: l.colour, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.name, style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                      Text('EMI ${money(l.emiAmount)} · due day ${l.dueDay}', style: TextStyle(color: c.muted, fontSize: 12)),
                    ])),
                    IconButton(icon: Icon(Icons.delete_outline, color: c.muted),
                      onPressed: () { Notifs.cancelId(l.notifId); Store.instance.removeLoan(l.id); }),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: l.progress, minHeight: 9,
                      backgroundColor: c.field, color: l.isDone ? kGreen : l.colour)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text('${l.paidMonths}/${l.totalMonths} months · ${money(l.remaining)} left',
                      style: TextStyle(fontSize: 12, color: c.muted)),
                    const Spacer(),
                    if (l.paidMonths > 0)
                      IconButton(iconSize: 20, icon: Icon(Icons.undo, color: c.muted),
                        onPressed: () => Store.instance.undoEmi(l.id)),
                    if (!l.isDone)
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: l.colour,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
                        onPressed: () => Store.instance.payEmi(l.id),
                        child: const Text('Pay EMI', style: TextStyle(fontSize: 13)))
                    else
                      const Text('🎉 Paid off', style: TextStyle(color: kGreen, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              );
            }),
        ]);
      }),
    );
  }
}
