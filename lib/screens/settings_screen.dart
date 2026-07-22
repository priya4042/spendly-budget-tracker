import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../store.dart';
import '../theme.dart';
import '../l10n.dart';
import '../notifications.dart';
import 'manage_screens.dart';
import 'presets_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Store get s => Store.instance;

  Future<void> _setPin() async {
    final ctrl = TextEditingController();
    final c = AppC.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: c.card,
      title: Text('Set a 4-digit PIN', style: TextStyle(color: c.text)),
      content: TextField(controller: ctrl, autofocus: true, obscureText: true, maxLength: 4,
        keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(color: c.text, letterSpacing: 8, fontSize: 22),
        decoration: const InputDecoration(counterText: '', hintText: '••••')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
      ],
    ));
    if (ok == true && ctrl.text.length == 4) {
      s.pin = ctrl.text; s.lockEnabled = true; await s.saveSettings();
    } else {
      setState(() {});
    }
  }

  Future<void> _toggleReminder(bool on) async {
    s.reminderEnabled = on;
    await s.saveSettings();
    if (on) {
      await Notifs.requestPermission();
      await Notifs.scheduleDaily(s.reminderHour, s.reminderMinute);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Daily reminder set for ${_timeLabel()}')));
      }
    } else {
      await Notifs.cancelDaily();
    }
    setState(() {});
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context,
      initialTime: TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute));
    if (t != null) {
      s.reminderHour = t.hour; s.reminderMinute = t.minute;
      await s.saveSettings();
      if (s.reminderEnabled) await Notifs.scheduleDaily(t.hour, t.minute);
      setState(() {});
    }
  }

  String _timeLabel() {
    final t = TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute);
    return t.format(context);
  }

  Future<void> _exportCsv() async {
    final csv = s.buildCsv();
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(utf8.encode(csv), mimeType: 'text/csv', name: 'spendly_export.csv')],
      text: 'Spendly transactions export',
    ));
  }

  Future<void> _backup() async {
    final json = s.buildBackupJson();
    // Copy to clipboard too, so restore-by-paste is easy.
    await Clipboard.setData(ClipboardData(text: json));
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(utf8.encode(json), mimeType: 'application/json', name: 'spendly_backup.json')],
      text: 'Spendly full backup (also copied to clipboard). Keep it safe to restore your data.',
    ));
  }

  /// Restore by pasting the backup JSON (from clipboard / the backup file text).
  Future<void> _restore() async {
    final ctrl = TextEditingController();
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip?.text != null && clip!.text!.trim().startsWith('{')) ctrl.text = clip.text!;
    final c = AppC.of(context);
    if (!mounted) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: c.card,
      title: Text('Restore backup', style: TextStyle(color: c.text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Paste your backup below (open the backup file, copy all, and paste). This REPLACES all current data.',
          style: TextStyle(color: c.muted, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(controller: ctrl, maxLines: 4, style: TextStyle(color: c.text, fontSize: 12),
          decoration: InputDecoration(hintText: '{ "version": 4, ... }', filled: true, fillColor: c.field,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
      ],
    ));
    if (ok != true) return;
    final success = await s.restoreBackupJson(ctrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Backup restored successfully' : 'Could not read that backup')));
    }
  }

  Future<void> _pickCurrency() async {
    const symbols = ['₹', '\$', '€', '£', '¥', '₩', '₨', '৳', 'R\$', 'A\$'];
    final c = AppC.of(context);
    await showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: c.card,
      title: Text(L.t('currency'), style: TextStyle(color: c.text)),
      content: Wrap(spacing: 10, runSpacing: 10, children: symbols.map((sym) => GestureDetector(
        onTap: () { s.currencySymbol = sym; s.saveSettings(); Navigator.pop(context); setState(() {}); },
        child: Container(width: 54, height: 48, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: s.currencySymbol == sym ? kGreen.withValues(alpha: 0.15) : c.field,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: s.currencySymbol == sym ? kGreen : Colors.transparent, width: 2)),
          child: Text(sym, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700))),
      )).toList()),
    ));
  }

  Future<void> _pickLanguage() async {
    final c = AppC.of(context);
    await showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: c.card,
      title: Text(L.t('language'), style: TextStyle(color: c.text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final e in {'en': 'English', 'hi': 'हिंदी'}.entries)
          RadioListTile<String>(value: e.key, groupValue: s.lang, activeColor: kGreen,
            title: Text(e.value, style: TextStyle(color: c.text)),
            onChanged: (v) { s.lang = v!; s.saveSettings(); Navigator.pop(context); setState(() {}); }),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) => ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
          _section(L.t('appearance'), c),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: c.text),
            title: Text(L.t('darkMode'), style: TextStyle(color: c.text)),
            value: s.darkMode,
            activeThumbColor: kGreen,
            onChanged: (v) { s.darkMode = v; s.saveSettings(); },
          ),
          ListTile(
            leading: Icon(Icons.language, color: c.text),
            title: Text(L.t('language'), style: TextStyle(color: c.text)),
            trailing: Text(s.lang == 'hi' ? 'हिंदी' : 'English', style: const TextStyle(color: kGreen, fontWeight: FontWeight.w600)),
            onTap: _pickLanguage,
          ),
          _section(L.t('security'), c),
          SwitchListTile(
            secondary: Icon(Icons.lock_outline, color: c.text),
            title: Text('App lock (PIN / fingerprint)', style: TextStyle(color: c.text)),
            subtitle: Text(s.lockEnabled ? 'Enabled' : 'Off', style: TextStyle(color: c.muted)),
            value: s.lockEnabled, activeThumbColor: kGreen,
            onChanged: (v) {
              if (v) { _setPin(); }
              else { s.lockEnabled = false; s.pin = ''; s.saveSettings(); }
            },
          ),
          _section(L.t('reminders'), c),
          SwitchListTile(
            secondary: Icon(Icons.notifications_outlined, color: c.text),
            title: Text('Daily reminder', style: TextStyle(color: c.text)),
            subtitle: Text('Remind me to log expenses', style: TextStyle(color: c.muted)),
            value: s.reminderEnabled, activeThumbColor: kGreen,
            onChanged: _toggleReminder,
          ),
          if (s.reminderEnabled)
            ListTile(
              leading: Icon(Icons.schedule, color: c.text),
              title: Text('Reminder time', style: TextStyle(color: c.text)),
              trailing: Text(_timeLabel(), style: const TextStyle(color: kGreen, fontWeight: FontWeight.w600)),
              onTap: _pickTime,
            ),
          _section(L.t('manage'), c),
          _navTile(c, Icons.account_balance_wallet_outlined, 'Wallets',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageWalletsScreen()))),
          _navTile(c, Icons.category_outlined, 'Categories',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()))),
          _navTile(c, Icons.bolt, 'Quick-add presets',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetsScreen()))),
          _navTile(c, Icons.repeat, 'Recurring transactions',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen()))),
          ListTile(
            leading: Icon(Icons.currency_exchange, color: c.text),
            title: Text(L.t('currency'), style: TextStyle(color: c.text)),
            trailing: Text(s.currencySymbol, style: const TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 16)),
            onTap: _pickCurrency,
          ),
          _section('Savings', c),
          SwitchListTile(
            secondary: Icon(Icons.savings_outlined, color: c.text),
            title: Text('Round-up savings', style: TextStyle(color: c.text)),
            subtitle: Text('Save spare change from each expense', style: TextStyle(color: c.muted)),
            value: s.roundUpEnabled, activeThumbColor: kGreen,
            onChanged: (v) { s.roundUpEnabled = v; s.saveSettings(); },
          ),
          if (s.roundUpEnabled)
            ListTile(
              leading: Icon(Icons.tune, color: c.text),
              title: Text('Round up to nearest', style: TextStyle(color: c.text)),
              trailing: DropdownButton<int>(
                value: s.roundUpNearest, dropdownColor: c.card, underline: const SizedBox(),
                style: const TextStyle(color: kGreen, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('₹10')),
                  DropdownMenuItem(value: 50, child: Text('₹50')),
                  DropdownMenuItem(value: 100, child: Text('₹100')),
                ],
                onChanged: (v) { s.roundUpNearest = v ?? 10; s.saveSettings(); },
              ),
            ),
          _section(L.t('data'), c),
          _navTile(c, Icons.backup_outlined, 'Backup (save all data)', _backup),
          _navTile(c, Icons.restore, 'Restore from backup', _restore),
          _navTile(c, Icons.file_download_outlined, 'Export to CSV', _exportCsv),
          const SizedBox(height: 20),
          Center(child: Text('Spendly · Priya Tech Lab', style: TextStyle(color: c.muted, fontSize: 12))),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _section(String title, AppC c) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
    child: Text(title.toUpperCase(),
      style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)));

  Widget _navTile(AppC c, IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: c.text),
    title: Text(title, style: TextStyle(color: c.text)),
    trailing: Icon(Icons.chevron_right, color: c.muted),
    onTap: onTap,
  );
}
