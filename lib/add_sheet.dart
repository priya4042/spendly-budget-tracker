import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';

Future<bool?> showAddSheet(BuildContext context, {Txn? edit}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddSheet(),
  );
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  bool _isExpense = true;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late String _category = Store.instance.categoriesFor(true).first.name;
  String _walletId = Store.instance.wallets.first.id;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _switchType(bool expense) {
    setState(() {
      _isExpense = expense;
      _category = Store.instance.categoriesFor(expense).first.name;
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date,
        firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    await Store.instance.add(Txn(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount, isExpense: _isExpense, category: _category, walletId: _walletId,
      note: _noteCtrl.text.trim(),
      timestamp: DateTime(_date.year, _date.month, _date.day, DateTime.now().hour, DateTime.now().minute)
          .millisecondsSinceEpoch,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    final accent = _isExpense ? kRed : kGreen;
    final cats = Store.instance.categoriesFor(_isExpense);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: c.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: c.muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            Container(
              decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(4),
              child: Row(children: [_typeBtn('Expense', true, kRed, c), _typeBtn('Income', false, kGreen, c)]),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountCtrl, autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: accent),
              decoration: InputDecoration(prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: accent),
                hintText: '0', border: InputBorder.none),
            ),
            Divider(color: c.muted.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Text('Category', style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: cats.map((cat) {
              final sel = cat.name == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = cat.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? cat.colour.withValues(alpha: 0.15) : c.field,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? cat.colour : Colors.transparent, width: 1.5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(cat.icon, size: 18, color: cat.colour), const SizedBox(width: 6),
                    Text(cat.name, style: TextStyle(color: c.text, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            Text('Wallet', style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: Store.instance.wallets.map((w) {
              final sel = w.id == _walletId;
              return GestureDetector(
                onTap: () => setState(() => _walletId = w.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? w.colour.withValues(alpha: 0.15) : c.field,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? w.colour : Colors.transparent, width: 1.5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(w.icon, size: 18, color: w.colour), const SizedBox(width: 6),
                    Text(w.name, style: TextStyle(color: c.text, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _noteCtrl,
                style: TextStyle(color: c.text),
                decoration: InputDecoration(hintText: 'Note (optional)', filled: true, fillColor: c.field,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
              const SizedBox(width: 10),
              InkWell(onTap: _pickDate, borderRadius: BorderRadius.circular(12),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.calendar_today, size: 18, color: c.text))),
            ]),
            const SizedBox(height: 6),
            Text('Date: ${_date.day}/${_date.month}/${_date.year}', style: TextStyle(fontSize: 12, color: c.muted)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _save,
              child: Text(_isExpense ? 'Add Expense' : 'Add Income',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)))),
          ]),
        ),
      ),
    );
  }

  Widget _typeBtn(String label, bool expense, Color color, AppC c) {
    final sel = _isExpense == expense;
    return Expanded(child: GestureDetector(onTap: () => _switchType(expense),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(color: sel ? c.card : Colors.transparent, borderRadius: BorderRadius.circular(9),
          boxShadow: sel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)] : null),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, color: sel ? color : c.muted)))));
  }
}
