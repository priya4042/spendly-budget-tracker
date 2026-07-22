import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  Future<void> _editBudget(BuildContext context, CatDef cat) async {
    final ctrl = TextEditingController(
      text: Store.instance.budgetFor(cat.name) > 0 ? Store.instance.budgetFor(cat.name).toStringAsFixed(0) : '');
    final c = AppC.of(context);
    await showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: c.card,
      title: Text('${cat.name} budget', style: TextStyle(color: c.text)),
      content: TextField(controller: ctrl, autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: TextStyle(color: c.text),
        decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Monthly limit')),
      actions: [
        TextButton(onPressed: () { Store.instance.setBudget(cat.name, 0); Navigator.pop(context); },
          child: const Text('Remove')),
        FilledButton(onPressed: () {
          Store.instance.setBudget(cat.name, double.tryParse(ctrl.text.trim()) ?? 0);
          Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (context, _) {
        final s = Store.instance;
        final m = s.selectedMonth;
        final cats = s.categoriesFor(true);
        return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), children: [
          Text('Budgets', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text)),
          Text(monthLabel(m), style: TextStyle(color: c.muted, fontSize: 13)),
          const SizedBox(height: 6),
          Text('Tap a category to set a monthly limit', style: TextStyle(color: c.muted, fontSize: 12)),
          const SizedBox(height: 16),
          ...cats.map((cat) {
            final limit = s.budgetFor(cat.name);
            final spent = s.categorySpent(cat.name, m);
            final has = limit > 0;
            final pct = (has ? (spent / limit) : 0.0).clamp(0.0, 1.0);
            final over = has && spent > limit;
            return GestureDetector(
              onTap: () => _editBudget(context, cat),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Row(children: [
                    Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: cat.colour.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(cat.icon, color: cat.colour, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(cat.name, style: TextStyle(fontWeight: FontWeight.w600, color: c.text))),
                    if (has)
                      Text('${money(spent)} / ${money(limit)}',
                        style: TextStyle(fontSize: 12, color: over ? kRed : c.muted, fontWeight: FontWeight.w600))
                    else
                      Text('Set budget', style: TextStyle(fontSize: 12, color: kGreen)),
                  ]),
                  if (has) ...[
                    const SizedBox(height: 12),
                    ClipRRect(borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: pct, minHeight: 8,
                        backgroundColor: c.field, color: over ? kRed : cat.colour)),
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerRight, child: Text(
                      over ? 'Over by ${money(spent - limit)}' : '${money(limit - spent)} left',
                      style: TextStyle(fontSize: 11, color: over ? kRed : c.muted))),
                  ],
                ]),
              ),
            );
          }),
        ]);
      },
    );
  }
}
