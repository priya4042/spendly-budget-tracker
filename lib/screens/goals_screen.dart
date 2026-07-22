import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../pickers.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  Future<void> _addGoal(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    String icon = 'savings';
    int color = kColors[0];
    final c = AppC.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(
      builder: (context, setD) => AlertDialog(
        backgroundColor: c.card,
        title: Text('New goal', style: TextStyle(color: c.text)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, style: TextStyle(color: c.text),
            decoration: const InputDecoration(hintText: 'Goal name (e.g. New phone)')),
          const SizedBox(height: 10),
          TextField(controller: targetCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            style: TextStyle(color: c.text), decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Target amount')),
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
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    ));
    if (ok == true) {
      final t = double.tryParse(targetCtrl.text.trim());
      if (nameCtrl.text.trim().isNotEmpty && t != null && t > 0) {
        await Store.instance.addGoal(Goal(id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: nameCtrl.text.trim(), target: t, iconKey: icon, color: color));
      }
    }
  }

  Future<void> _contribute(BuildContext context, Goal g) async {
    final ctrl = TextEditingController();
    final c = AppC.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: c.card,
      title: Text('Add to ${g.name}', style: TextStyle(color: c.text)),
      content: TextField(controller: ctrl, autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: TextStyle(color: c.text), decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Amount to add')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
      ],
    ));
    if (ok == true) {
      final a = double.tryParse(ctrl.text.trim());
      if (a != null && a > 0) await Store.instance.contributeGoal(g.id, a);
    }
  }

  Widget _roundUpCard(BuildContext context, Store s, AppC c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFF8F00)]),
        borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.savings, color: Colors.white),
          const SizedBox(width: 8),
          const Text('Round-up jar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Text(money(s.roundUpTotal), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 6),
        const Text('Spare change from your expenses, saved automatically.',
          style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 10),
        Row(children: [
          TextButton(onPressed: s.roundUpTotal > 0 ? () => _moveToGoal(context, s) : null,
            style: TextButton.styleFrom(foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2)),
            child: const Text('Move to a goal')),
          const SizedBox(width: 8),
          TextButton(onPressed: s.roundUpTotal > 0 ? () => s.resetRoundUp() : null,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Reset')),
        ]),
      ]),
    );
  }

  Future<void> _moveToGoal(BuildContext context, Store s) async {
    if (s.goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a goal first')));
      return;
    }
    final c = AppC.of(context);
    await showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: c.card,
      title: Text('Move ${money(s.roundUpTotal)} to…', style: TextStyle(color: c.text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: s.goals.map((g) => ListTile(
        leading: Icon(g.icon, color: g.colour),
        title: Text(g.name, style: TextStyle(color: c.text)),
        onTap: () { s.moveRoundUpToGoal(g.id); Navigator.pop(context); },
      )).toList()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      floatingActionButton: FloatingActionButton(backgroundColor: kGreen, foregroundColor: Colors.white,
        onPressed: () => _addGoal(context), child: const Icon(Icons.add)),
      body: ListenableBuilder(listenable: Store.instance, builder: (context, _) {
        final s = Store.instance;
        final gs = s.goals;
        return ListView(padding: const EdgeInsets.all(16), children: [
          if (s.roundUpEnabled || s.roundUpTotal > 0) _roundUpCard(context, s, c),
          if (gs.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Column(children: [
              Icon(Icons.savings_outlined, size: 56, color: c.muted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('No savings goals yet', style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
              const SizedBox(height: 4),
              Text('Set a goal and watch it grow', style: TextStyle(color: c.muted)),
            ]))),
          ...gs.map((g) {
          final done = g.saved >= g.target;
          return Container(
            margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: g.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(g.icon, color: g.colour, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.name, style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                  Text('${money(g.saved)} of ${money(g.target)}', style: TextStyle(color: c.muted, fontSize: 12)),
                ])),
                IconButton(icon: Icon(Icons.delete_outline, color: c.muted),
                  onPressed: () => Store.instance.removeGoal(g.id)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: g.progress, minHeight: 10,
                  backgroundColor: c.field, color: done ? kGreen : g.colour)),
              const SizedBox(height: 10),
              Row(children: [
                Text(done ? '🎉 Goal reached!' : '${(g.progress * 100).toStringAsFixed(0)}% saved',
                  style: TextStyle(fontSize: 12, color: done ? kGreen : c.muted, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (!done)
                  TextButton.icon(onPressed: () => _contribute(context, g),
                    icon: const Icon(Icons.add, size: 18), label: const Text('Add money')),
              ]),
            ]),
          );
        }),
        ]);
      }),
    );
  }
}
