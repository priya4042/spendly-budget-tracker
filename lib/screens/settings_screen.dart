import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../store.dart';
import '../theme.dart';
import '../notifications.dart';
import 'manage_screens.dart';

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

  @override
  Widget build(BuildContext context) {
    final c = AppC.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) => ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
          _section('Appearance', c),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: c.text),
            title: Text('Dark mode', style: TextStyle(color: c.text)),
            value: s.darkMode,
            activeThumbColor: kGreen,
            onChanged: (v) { s.darkMode = v; s.saveSettings(); },
          ),
          _section('Security', c),
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
          _section('Reminders', c),
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
          _section('Manage', c),
          _navTile(c, Icons.account_balance_wallet_outlined, 'Wallets',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageWalletsScreen()))),
          _navTile(c, Icons.category_outlined, 'Categories',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()))),
          _navTile(c, Icons.repeat, 'Recurring transactions',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen()))),
          _section('Data', c),
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
