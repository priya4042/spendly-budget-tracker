import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'util.dart';
import 'l10n.dart';

Future<bool?> showAddSheet(BuildContext context, {Txn? edit}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddSheet(edit: edit),
  );
}

class _AddSheet extends StatefulWidget {
  final Txn? edit;
  const _AddSheet({this.edit});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  late bool _isExpense = widget.edit?.isExpense ?? true;
  late final _amountCtrl = TextEditingController(
      text: widget.edit != null ? _trim(widget.edit!.amount) : '');
  late final _noteCtrl = TextEditingController(text: widget.edit?.note ?? '');
  late String _category =
      widget.edit?.category ?? Store.instance.categoriesFor(true).first.name;
  late String _walletId = widget.edit?.walletId ?? Store.instance.wallets.first.id;
  late DateTime _date = widget.edit?.date ?? DateTime.now();

  static String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() { _amountCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  void _switchType(bool expense) => setState(() {
    _isExpense = expense;
    _category = Store.instance.categoriesFor(expense).first.name;
  });

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date,
        firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final amount = evalExpr(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final ts = DateTime(_date.year, _date.month, _date.day, DateTime.now().hour, DateTime.now().minute)
        .millisecondsSinceEpoch;
    final t = Txn(
      id: widget.edit?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount, isExpense: _isExpense, category: _category, walletId: _walletId,
      note: _noteCtrl.text.trim(), timestamp: widget.edit != null ? widget.edit!.timestamp : ts,
    );
    if (widget.edit != null) { await Store.instance.update(t); } else { await Store.instance.add(t); }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    final accent = _isExpense ? kRed : kGreen;
    final cats = Store.instance.categoriesFor(_isExpense);
    final computed = evalExpr(_amountCtrl.text.trim());
    final showCalc = _amountCtrl.text.contains(RegExp(r'[+\-*/]')) && computed != null;
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
              child: Row(children: [_typeBtn(L.t('expense'), true, kRed, c), _typeBtn(L.t('income'), false, kGreen, c)]),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountCtrl, autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.+\-*/]'))],
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: accent),
              decoration: InputDecoration(prefixText: '${Store.instance.currencySymbol} ',
                prefixStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: accent),
                hintText: '0', border: InputBorder.none),
            ),
            if (showCalc)
              Padding(padding: const EdgeInsets.only(left: 2),
                child: Text('= ${money(computed)}', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600))),
            Divider(color: c.muted.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Text(L.t('category'), style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
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
            Text(L.t('wallet'), style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
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
              Expanded(child: TextField(controller: _noteCtrl, style: TextStyle(color: c.text),
                decoration: InputDecoration(hintText: L.t('note'), filled: true, fillColor: c.field,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
              const SizedBox(width: 10),
              InkWell(onTap: _pickDate, borderRadius: BorderRadius.circular(12),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.calendar_today, size: 18, color: c.text))),
            ]),
            const SizedBox(height: 6),
            Text('${_date.day}/${_date.month}/${_date.year}', style: TextStyle(fontSize: 12, color: c.muted)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _save,
              child: Text(widget.edit != null ? L.t('save') : (_isExpense ? L.t('addExpense') : L.t('addIncome')),
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
